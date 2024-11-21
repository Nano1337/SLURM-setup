# Slurm Single-Node GPU Setup Guide

This guide details how to set up Slurm on a single node with GPU support (tested on Ubuntu with NVIDIA L40S).

## Prerequisites

Ensure you have a GPU-enabled instance with NVIDIA drivers and CUDA installed. You can verify with:
```bash
nvidia-smi
nvcc -V
```

## Installation Steps

1. Install required packages:
```bash
sudo apt-get update
sudo apt-get install slurm-wlm slurmdbd mysql-server
```

2. Create necessary directories and set permissions:
```bash
sudo mkdir -p /etc/slurm
sudo mkdir -p /var/spool/slurm/ctld
sudo mkdir -p /var/spool/slurm/d
sudo mkdir -p /var/log/slurm
sudo mkdir -p /var/run/slurm
sudo chown -R slurm:slurm /var/spool/slurm
sudo chown -R slurm:slurm /var/log/slurm
sudo chown -R slurm:slurm /var/run/slurm
```

3. Configure MySQL for Slurm:
```bash
sudo mysql -u root

# In MySQL prompt:
CREATE USER 'slurm'@'localhost' IDENTIFIED BY 'password';
CREATE DATABASE slurm_acct_db;
GRANT ALL ON slurm_acct_db.* TO 'slurm'@'localhost';
quit;
```

4. Create slurmdbd.conf:
```bash
sudo nano /etc/slurm/slurmdbd.conf
```

Add this content:
```ini
AuthType=auth/munge
DbdAddr=localhost
DbdHost=localhost
SlurmUser=slurm
DebugLevel=4
LogFile=/var/log/slurm/slurmdbd.log
PidFile=/var/run/slurmdbd.pid
StorageType=accounting_storage/mysql
StorageHost=localhost
StoragePass=password
StorageUser=slurm
StorageLoc=slurm_acct_db
```

5. Set proper permissions for slurmdbd.conf:
```bash
sudo chown slurm:slurm /etc/slurm/slurmdbd.conf
sudo chmod 600 /etc/slurm/slurmdbd.conf
```

6. Create slurm.conf:
```bash
sudo nano /etc/slurm/slurm.conf
```

Add this content (adjust memory and CPU values according to your system):
```ini
ClusterName=localhost
SlurmctldHost=localhost
SlurmUser=slurm

# ACCOUNT MANAGEMENT
AccountingStorageType=accounting_storage/slurmdbd
AccountingStorageHost=localhost
JobAcctGatherType=jobacct_gather/linux

# SCHEDULING
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core_Memory

# MPI Configuration
MpiDefault=none

# GRES Configuration
GresTypes=gpu

# LOGGING
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log

# State save locations
StateSaveLocation=/var/spool/slurm/ctld
SlurmdSpoolDir=/var/spool/slurm/d

# COMPUTE NODES
NodeName=localhost CPUs=4 RealMemory=31640 State=UNKNOWN Gres=gpu:1
PartitionName=main Nodes=localhost Default=YES MaxTime=INFINITE State=UP
```

7. Create gres.conf:
```bash
sudo nano /etc/slurm/gres.conf
```

Add this content:
```ini
NodeName=localhost Name=gpu File=/dev/nvidia0 Count=1
```

8. Start services in the correct order:
```bash
sudo systemctl enable slurmdbd
sudo systemctl start slurmdbd
sudo systemctl enable slurmctld
sudo systemctl start slurmctld
sudo systemctl enable slurmd
sudo systemctl start slurmd
```

9. Set up Slurm accounting:
```bash
sudo sacctmgr add cluster linux
sudo sacctmgr add account ubuntu description="Ubuntu Account" organization="Local"
sudo sacctmgr add user ubuntu account=ubuntu
sudo sacctmgr add qos standard_priority set priority=100
```

10. Resume the node:
```bash
sudo scontrol update nodename=localhost state=resume
```

## Testing the Setup

1. Create a test GPU job:
```bash
nano test_gpu.sh
```

Add this content:
```bash
#!/bin/bash
#SBATCH --job-name=test_gpu
#SBATCH --output=test_gpu_%j.out
#SBATCH --error=test_gpu_%j.err
#SBATCH --gres=gpu:l40s:1
#SBATCH --partition=debug
#SBATCH --account=ubuntu

nvidia-smi
```

2. Submit and check the job:
```bash
chmod +x test_gpu.sh
sbatch test_gpu.sh
squeue
```

## Verification Commands

Check the setup with:
```bash
sinfo                    # Check partition and node status
scontrol show node      # View detailed node information
scontrol show partition # View partition information
```

## Troubleshooting

If you encounter issues:
1. Check service status:
```bash
systemctl status slurmdbd
systemctl status slurmctld
systemctl status slurmd
```

2. View logs:
```bash
sudo journalctl -xe -u slurmdbd
sudo journalctl -xe -u slurmctld
sudo journalctl -xe -u slurmd
```
