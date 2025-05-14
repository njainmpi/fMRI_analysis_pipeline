import os
import sys
import numpy as np
import matplotlib.pyplot as plt

def load_data(filepath):
    """Load tabular data from a space-delimited file."""
    with open(filepath, "r") as file:
        lines = [line.strip().split() for line in file if line.strip()]
    data = np.array(lines, dtype=float)
    return data

def process_and_plot(data, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    
    # Set default font size globally (affects most elements)
    plt.rcParams.update({'font.size': 40})
    
    # Transpose to work column-wise
    data = data.T
    num_voxels = data.shape[0]

    for idx in range(num_voxels):
        col_data = data[idx]

        # Step 1: Calculate baseline from rows 50 to 550
        baseline = np.mean(col_data[50:551])  # 551 to include row 550

        # Step 2: Calculate percentage change for rows 3 to end
        normalized = ((col_data[3:] - baseline) / baseline) * 100

        # Step 3: Retrieve x, y, z labels from rows 0, 1, 2
        x = col_data[0]
        y = col_data[1]
        z = col_data[2]
        label = f"x={x}, y={y}, z={z}"

        # Step 4: Plot and save
        plt.figure(figsize=(30, 15))
        plt.plot(normalized, label=label)
        plt.title("Signal Change Plots")
        plt.xlabel("Time (in sec)", fontsize=40)
        plt.ylabel("Percent Signal Change", fontsize=40)
        plt.legend()
        plt.grid(True)

        # Save as vector image
        # Create a safe filename using voxel coordinates
        filename = f"x{x}_y{y}_z{z}.svg"
        plt.savefig(os.path.join(output_dir, filename), format='svg', bbox_inches='tight')
        plt.close()


        # filename = f"voxel_{idx}.svg"
        # plt.savefig(os.path.join(output_dir, filename), format='svg')
        # plt.close()

    print(f"All plots saved to '{output_dir}'")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python plot_voxels.py <input_file> <output_folder>")
        sys.exit(1)

    input_path = sys.argv[1]
    output_folder = sys.argv[2]

    data = load_data(input_path)
    process_and_plot(data, output_folder)
