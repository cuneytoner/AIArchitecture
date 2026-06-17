#!/bin/bash

# Use absolute paths for copying Systemd service files
sudo cp /home/cuneyt/DiskD/Projects/AIArchitecture/Services/ai-memory-agent.service /etc/systemd/system/
sudo cp /home/cuneyt/DiskD/Projects/AIArchitecture/Services/ai-celery-worker.service /etc/systemd/system/

# Reload Systemd daemon
sudo systemctl daemon-reload

# Enable and start the services
sudo systemctl enable ai-memory-agent.service
sudo systemctl enable ai-celery-worker.service
sudo systemctl start ai-memory-agent.service
sudo systemctl start ai-celery-worker.service