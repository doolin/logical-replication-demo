#!/bin/bash

tmux new-session -d -s container-logs
tmux split-window -h -t container-logs
tmux send-keys -t container-logs:0.0 'docker logs -f subscriber1' C-m
tmux send-keys -t container-logs:0.1 'docker logs -f subscriber2' C-m
tmux attach -t container-logs
