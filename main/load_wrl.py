import numpy as np

def load_wrl(sourcefile):
    flag_faces = 'coordIndex z['
    fid = open(sourcefile, 'rt')

    #T = textscan(fid, '%d %d %d -1', 'WhiteSpace', ' \b\t,');
    regexp = r"\s+([0-9.\-]+) ([0-9.\-]+) ([0-9.\-]+) \-1"
    dt = [('x', np.float32), ('y',  np.float32), ('z',  np.float32)]
    text = np.fromregex(fid, regexp, dt)

    fid.close()

    a = []
    for item in text:
        a.append(np.float32([item['x'], item['y'], item['z'], ]))
    print(a)
    return a

if __name__ == "__main__":
    #load_wrl('../data/180914075154ER.wrl')
    load_wrl('../data/notes.txt')
    print("done")