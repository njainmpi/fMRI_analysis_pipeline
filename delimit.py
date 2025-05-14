import sys

def reformat_space_to_tab(input_path, output_path):
    try:
        with open(input_path, "r") as infile, open(output_path, "w") as outfile:
            for line in infile:
                if line.strip():  # Skip empty lines
                    parts = line.strip().split()  # Split by any whitespace
                    outfile.write("\t".join(parts) + "\n")  # Join with tabs
        print(f"File successfully reformatted to tab-delimited format: {output_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Command-line usage: python space_to_tab.py input.txt output.txt
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python space_to_tab.py <input_file> <output_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    reformat_space_to_tab(input_file, output_file)
