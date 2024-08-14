function app_annotate(fldwrl, fldlnd, lnddef)
% Annotate all 3D images in the given folder.
%
% Left mouse button marks coordinate, press <space> to put landmark there.
% Right mouse button selects placed landmarks, press <x> (or <del>) to delete.
% Press <s> to save.
% Save and go to previous / next scan with <p> and <n> respectively.
% Save and quit with <q> or close the window to quit without saving.
%
% Input arguments:
%  FLDWRL  Folder with all .wrl files.
%  FLDLND  Optional folder to which .lnd annotation files will be written.
%          Annotation files will match image file names: AAA.wrl -> AAA.lnd
%          Existing annotation files will be loaded automatically.
%          Default value is FLDWRL.
%  LNDDEF  Optional landmark definition for loading annotation files. Can be
%          specified by its name or file name as a string.
%          Default value is 'Tena-26'.
%
% TODO: toggle texture.
% TODO: render numbers always on top. (is it possible?)
%
  if nargin<1 || isempty(fldwrl)
    disp('No source folder specified.');
    return;
  end
  if nargin<2 || isempty(fldlnd), fldlnd=fldwrl; end
  if nargin<3 || isempty(lnddef), lnddef=LandmarkDefinition.tena26; end

  if ischar(lnddef)
    lnddef = LandmarkDefinition.load(lnddef);
  end

  hfig = figure('Renderer','OpenGL', 'MenuBar','none', 'ToolBar','none');

  s.hfig = hfig;
  s.haxes = gca;

  s.annotationui = AnnotationUI(lnddef, s.haxes);
  s.files = FileAnnotationSequence(fldwrl, fldlnd);
  s.viewer = MeshViewerContext(s.haxes);

  aui = s.annotationui;

  s.kc = KeyboardContext(hfig, { ...
    % <enter> : add point to landmarks
    'space',      @aui.putmarker;
    'return',     @aui.putmarker;
    ' ',          @aui.putmarker;
    %  `x`    : delete selected landmark
    'delete',     @aui.deletemarker;
    'backspace',  @aui.deletemarker;
    'x',          @aui.deletemarker;
    %  `>`    : goto next landmark
    'rightarrow', @aui.selectnextmarker;
    'downarrow',  @aui.selectnextmarker;
    'period',     @aui.selectnextmarker;
    '.',          @aui.selectnextmarker;
    '>',          @aui.selectnextmarker;
    %  `<`    : goto previous landmark
    'leftarrow',  @aui.selectpreviousmarker;
    'uparrow',    @aui.selectpreviousmarker;
    'comma',      @aui.selectpreviousmarker;
    ',',          @aui.selectpreviousmarker;
    '<',          @aui.selectpreviousmarker;
    %  `t`    : switch texture on/off
    't',          @toggletexture;
    %  `s`    : save, but stay in this figure
    's',          @saveselected;
    %  `g`    : goto specific scan number
    'g',          @gotonumber;
    %  `n`    : next image
    'n',          @gotonext;
    %  `p`    : previous image
    'p',          @gotoprevious;
    %  `q`    : quit
    % XXX: remove this?
    'q',          @quitapp;
  });

  addlistener(s.viewer, 'PointAtObject',clickhandler(s));

  renderselected(s);
  guidata(hfig, s);
end

% -----------------------------------------------------------------------------

function toggletexture(hfig, varargin)
  state = guidata(hfig);
  state.viewer.toggleTexture();
end

function gotonext(hfig, varargin)
  state = guidata(hfig);
  if checkclean(state)
    if state.files.next()
      renderselected(state);
    else
      msgbox('You are at the end of the sequence.', 'Annotate3D');
    end
  end
end

function gotoprevious(hfig, varargin)
  state = guidata(hfig);
  if checkclean(state)
    if state.files.previous()
      renderselected(state);
    else
      msgbox('You are at the start of the sequence.', 'Annotate3D');
    end
  end
end

function gotonumber(hfig, varargin)
  state = guidata(hfig);
  if checkclean(state)
    number = inputdlg(...
              sprintf('Jump to image number (1-%d):', state.files.numfiles), ...
              'Annotate3D', 1, {num2str(state.files.selected)});
    number = str2double(number);
    if state.files.goto(number)
      renderselected(state);
    else
      msgbox('Invalid image number.', 'Annotate3D');
    end
  end
end

function saved = saveselected(hfig, varargin)
  state = guidata(hfig);
  filename = state.files.selectedannotation;
  saved = state.annotationui.saveannotation(filename);
end

function quitapp(hfig, varargin)
  state = guidata(hfig);
  if checkclean(state)
    close(state.hfig);
  end
end

% -----------------------------------------------------------------------------

function cont = checkclean(state)
% Check with the user that we are OK to continue.
  aui = state.annotationui;
  if aui.dirty
    answer = questdlg('You have unsaved changes.', 'Annotate3D', ...
                      'Save', 'Discard', 'Cancel', 'Save');
    switch answer
      case 'Save'
        cont = saveselected(state.hfig);
      case 'Discard'
        % Nothing to do.
        cont = true;
      case 'Cancel'
        cont = false;
    end
  else
    cont = true;
  end
end

function renderselected(state)
  state.viewer.load(state.files.selectedsource);
  axis(state.haxes, 'off');

  if exist(state.files.selectedannotation, 'file')
    state.annotationui.loadannotation(state.files.selectedannotation);
  else
    state.annotationui.reset();
  end

  figtitle = sprintf('Annotate3D -- %d/%d:  %s', ...
              state.files.selected, state.files.numfiles, ...
              state.files.selectedannotation);
  set(state.hfig, 'NumberTitle','off', 'Name',figtitle);
end

% -----------------------------------------------------------------------------

function handler = clickhandler(state)
  function fcn(~, eventdata)
    switch eventdata.Button
      case 'left'
        state.annotationui.pointat(eventdata.Position);
      case 'right'
        state.annotationui.selectat(eventdata.Position);
    end
  end
  handler = @fcn;
end
