import subprocess

result = subprocess.run(['flutter', 'analyze', '--no-pub'], capture_output=True, text=True, cwd='c:\\Users\\athma\\OneDrive\\Desktop\\Mini Project\\gowayanad')
print(result.stdout)
print(result.stderr)
