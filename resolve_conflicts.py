import sys

def resolve(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith('<<<<<<<'):
            i += 1
            # collect HEAD
            while not lines[i].startswith('======='):
                out.append(lines[i])
                i += 1
            i += 1 # skip =======
            # collect theirs
            while not lines[i].startswith('>>>>>>>'):
                out.append(lines[i])
                i += 1
            i += 1 # skip >>>>>>>
        else:
            out.append(line)
            i += 1
            
    with open(filename, 'w') as f:
        f.writelines(out)

resolve('CHANGELOG.md')
resolve('.claude/work-state.md')
