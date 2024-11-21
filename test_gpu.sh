#!/bin/bash
#SBATCH --job-name=test_gpu
#SBATCH --output=test_gpu_%j.out
#SBATCH --error=test_gpu_%j.err
#SBATCH --gres=gpu:1
#SBATCH --partition=debug

nvidia-smi
