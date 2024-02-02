import shutil

file_to_backup = '../files/git_status_nice.json'
backup_file = '../files/git_status_nice.json.bkup'
shutil.copyfile(file_to_backup, backup_file)

with open('../files/git_status_nice.json', 'r') as file:
    lines = file.readlines()

# Adding commas at the end of each line except the last one
for i in range(len(lines) - 1):
    lines[i] = lines[i].rstrip() + ',\n'

# Writing the modified content back to the file
with open('../files/git_status_nice.json', 'w') as file:
    file.writelines(lines)

with open('../files/git_status_nice.json', 'r') as file:
    lines = file.readlines()

# Add '[' at the beginning of the first line and ']' at the end of the last line
if len(lines) > 0:
    lines[0] = '[' + lines[0]
    lines[-1] = lines[-1].rstrip() + ']'

## Writing the modified content back to the file
with open('../files/git_status_nice.json', 'w') as file:
    file.writelines(lines)
