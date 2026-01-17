
import os

files_to_fix = [
    "scripts/download_pdfjs.sh",
    "launch.sh"
]

for file_path in files_to_fix:
    if os.path.exists(file_path):
        with open(file_path, 'rb') as f:
            content = f.read()
        
        # Replace Windows CRLF with Linux LF
        new_content = content.replace(b'\r\n', b'\n')
        
        with open(file_path, 'wb') as f:
            f.write(new_content)
        print(f"Converted {file_path} to LF line endings.")
    else:
        print(f"Warning: {file_path} not found.")
