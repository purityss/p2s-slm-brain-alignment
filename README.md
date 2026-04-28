# Code and Source Data for: Human-like sequential sound-to-meaning transfer drives artificial speech comprehension

This repository contains the source data and analytical scripts necessary to reproduce the main findings and generate the figures presented in the manuscript: **"Human-like sequential sound-to-meaning transfer drives artificial speech comprehension."**

To facilitate the peer-review process, the repository is organized by **Figure panels**, allowing reviewers to easily navigate, inspect, and reproduce specific results.

## 📁 Repository Structure

The code and data are organized into two primary directories within the `Source_data_code/` folder:

* `Main Figures/`: Contains data and scripts for Main Figures 1 to 5.
* `Extended/`: Contains data and scripts for Extended Data Figures 1 to 10.

Each sub-directory is named after the specific figure panel (e.g., `Fig4/c/`). Inside each panel folder, you will find:
1.  **.mat files**: The processed intermediate source data (e.g., representational dissimilarity matrices (RDMs), layer neuron counts, model performance matrices, or unit intervention ranks).
2.  **.m files**: The MATLAB scripts used to perform the final statistical analyses and generate the corresponding plot.

## 🛠 Prerequisites

* **MATLAB**: All analytical scripts are written in MATLAB. 
* **Toolboxes**: Some scripts may require standard MATLAB toolboxes (e.g., Statistics and Machine Learning Toolbox). 

## 🚀 Usage

To reproduce a specific figure panel:
1. Clone or download this repository to your local machine.
2. Open MATLAB and navigate to the specific directory of the desired figure panel.
3. Run the `.m` script provided in that folder. 
4. The script will automatically load the accompanying `.mat` files in the same directory and generate the final plot.

## 📌 Note to Reviewers

* **Data Privacy & Raw Signal:** Due to patient privacy regulations and the substantial storage size of raw human intracranial recordings (sEEG) and large-scale SLM activation weights, this repository provides the *intermediate processed source data* required to generate the final figures. 
* **Full Pipeline:** The complete pre-processing pipeline code (from continuous sEEG signals to temporal epochs) is available upon reasonable request and will be fully integrated into this repository upon final publication.

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.
