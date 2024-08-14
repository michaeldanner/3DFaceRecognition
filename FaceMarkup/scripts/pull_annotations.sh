#!/bin/sh

cd /vol/vssp/facecap/Oxford/faces/annotation
# recursive (although I think that's not needed anymore)
# backup, renames existing local copies to <filename>~
# update, skips files that have a more recent local copy
rsync -rbu ~eeg3vg/Desktop/annotation/data/oxfall/abdel/   manual-abdel/
rsync -rbu ~eeg3vg/Desktop/annotation/data/oxfall/antonio/ manual-antonio/
rsync -rbu ~eeg3vg/Desktop/annotation/data/oxfall/bruce/   manual-bruce/
rsync -rbu ~eeg3vg/Desktop/annotation/data/oxfall/dan/     manual-dan/
rsync -rbu ~eeg3vg/Desktop/annotation/data/oxfall/dev/     manual-dev/
rsync -rbu ~eeg3vg/Desktop/annotation/data/oxfall/ho/      manual-ho/
rsync -rbu ~eeg3vg/Desktop/annotation/data/oxfall/kasia/   manual-kasia/
rsync -rbu ~eeg3vg/Desktop/annotation/data/oxfall/paul/    manual-paul/

