import subprocess
import os

def run_analysis():
    project_path = r"c:\Users\athma\OneDrive\Desktop\Mini Project\gowayanad"
    output_file = os.path.join(project_path, "analysis_results_final.txt")
    try:
        # Run flutter analyze
        process = subprocess.Popen(
            ['flutter', 'analyze', '--no-pub'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=project_path,
            shell=True,
            text=True
        )
        stdout, stderr = process.communicate()
        
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("Analysis Output:\n")
            f.write(stdout)
            if stderr:
                f.write("\nErrors:\n")
                f.write(stderr)
        
        print(f"Analysis complete. Results written to {output_file}")
            
    except Exception as e:
        print(f"Failed to run analysis: {e}")

if __name__ == "__main__":
    run_analysis()
