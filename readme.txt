# Evolutional Normal Maps: 3D Face Representations for 2D-3D Face Recognition, Face Modelling, and Data Augmentation

This repository contains the source code and datasets used in the paper "Evolutional Normal Maps: 3D Face Representations for 2D-3D Face Recognition, Face Modelling, and Data Augmentation," presented at VISIGRAPP (5: VISAPP) 2022.

## Authors
- Michael Danner
- Thomas Weber
- Patrik Huber
- Muhammad Awais
- Matthias Rätsch
- Josef Kittler

## Paper Abstract
The paper introduces Evolutional Normal Maps, a novel approach to 3D face representation that enhances 2D-3D face recognition, face modelling, and data augmentation. By leveraging normal maps generated from 3D facial data, our method provides a robust framework for accurate face recognition and realistic face modelling, which can be used to augment existing datasets for improved performance in deep learning applications.

## Repository Contents
- **Source Code**: Implementation of the Evolutional Normal Maps method.
- **Datasets**: Sample datasets used in the experiments.
- **Pretrained Models**: Models trained using the Evolutional Normal Maps approach.
- **Documentation**: Detailed instructions on how to use the code and replicate the experiments.

## Getting Started

### Prerequisites
- Python 3.8 or later
- TensorFlow 2.4 or later
- NumPy
- OpenCV
- Other dependencies listed in `requirements.txt`

### Installation
1. Clone the repository:
    ```bash
    git clone https://github.com/michaeldanner/3DFaceRecognition.git
    ```

2. Install the required dependencies:
    ```bash
    pip install -r requirements.txt
    ```

### Usage
To run the experiments, follow these steps:

1. **Data Preparation**: Ensure your datasets are structured as expected. Refer to the `data/README.md` for details on dataset preparation.
2. **Training**: Train the model using the provided training scripts.
    ```bash
    python train.py --config configs/train_config.yaml
    ```
3. **Evaluation**: Evaluate the trained models on the test datasets.
    ```bash
    python evaluate.py --config configs/eval_config.yaml
    ```

### Results
The results of our experiments, including performance metrics and visualizations, can be found in the `results/` directory. Detailed analysis and discussion of these results are provided in the paper.

## Citation
If you use this code in your research, please cite our paper:

@inproceedings{danner2022evolutional,
title={Evolutional Normal Maps: 3D Face Representations for 2D-3D Face Recognition, Face Modelling and Data Augmentation.},
author={Danner, Michael and Weber, Thomas and Huber, Patrik and Awais, Muhammad and Rätsch, Matthias and Kittler, Josef},
booktitle={VISIGRAPP (5: VISAPP)},
pages={267--274},
year={2022}
}

## Acknowledgements
We would like to thank our collaborators and the institutions that supported this research. Special thanks to the reviewers for their valuable feedback.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
