import subprocess
import os

def run_analyze():
    project_path = r'c:\Users\athma\OneDrive\Desktop\Mini Project\gowayanad'
    try:
        # Run flutter analyze
        result = subprocess.run(['flutter', 'analyze'], capture_output=True, text=True, cwd=project_path)
        output = result.stdout
        
        # Split into lines
        lines = output.split('\n')
        
        # Categorize
        errors = [l for l in lines if 'error •' in l]
        warnings = [l for l in lines if 'warning •' in l]
        infos = [l for l in lines if 'info •' in l]
        
        print(f"Total Issues: {len(errors) + len(warnings) + len(infos)}")
        print(f"Errors: {len(errors)}")
        print(f"Warnings: {len(warnings)}")
        print(f"Infos: {len(infos)}")
        
        print("\n--- ERRORS ---")
        for e in errors[:20]:
            print(e)
            
        print("\n--- WARNINGS ---")
        for w in warnings[:20]:
            print(w)
            
    except Exception as e:
        print(f"Failed to run analysis: {e}")

if __name__ == "__main__":
    run_analyze()
