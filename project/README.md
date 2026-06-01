# Procedural Maze Generation Research Experiment

## Project Overview

This is a research application built with Godot Engine that investigates the effects of different maze generation algorithms on player intrinsic motivation and perceived cognitive workload.

## Research Context

**Experiment Title:** Measuring Player Intrinsic Motivation and Cognitive Load in Procedurally Generated Mazes

**Research Question:** Which maze generation algorithm among Recursive Backtracking, Sidewinder, and Recursive Division produces the highest intrinsic motivation and the lowest perceived cognitive workload in players?

### Objectives

- Evaluate three distinct maze generation algorithms through player interaction
- Measure intrinsic motivation levels using in-game metrics and player feedback
- Assess perceived cognitive workload during maze navigation
- Compare algorithm effectiveness in creating engaging and manageable gameplay experiences
- Analyze heat maps and player movement patterns to understand engagement and difficulty

## Maze Generation Algorithms

This experiment implements three different procedural maze generation algorithms:

### 1. **Recursive Backtracking**
- A depth-first search (DFS) based algorithm
- Creates long, winding corridors with many dead ends
- Tends to produce mazes with good visual complexity

### 2. **Sidewinder**
- A carving algorithm with horizontal bias
- Produces distinctive striped patterns
- Generally creates wider corridors with different spatial characteristics

### 3. **Recursive Division**
- A divide-and-conquer approach
- Creates mazes with a more structured, grid-like appearance
- Known for producing different challenge patterns compared to DFS-based methods

## Features

- **3D Maze Generation**: Procedurally generated 3D mazes using the three tested algorithms
- **Multiple Characters**: Support for different player characters (May, Twilight)
- **Performance Tracking**: Heatmap system to track player movement patterns
- **Checkpoint System**: Progression tracking through maze navigation
- **Intuitive Controls**: Camera and character movement controls optimized for player experience
- **Main Menu Interface**: User-friendly menu for experiment flow

## Project Structure

```
Maze_CC/
├── scenes/
│   ├── levels/           # Main maze level and game logic
│   ├── menus/            # Main menu interface
│   ├── ui/               # HUD and user interface elements
│   ├── player/           # Player and character scenes
│   └── environment/      # Floor, walls, and checkpoint elements
├── scripts/
│   ├── maze/             # Maze generation algorithms
│   ├── systems/          # Heatmap tracking and system utilities
│   ├── utils/            # Utility functions
│   ├── camera_3d.gd      # Camera control script
│   └── twilight_character.gd
├── characters/           # Character models and animations
│   ├── May/
│   └── Twilight For Unreal (with Animations)/
├── assets/               # Additional game resources
└── project.godot         # Godot project configuration
```

## Requirements

- **Godot Engine**: Version 4.6.1 or later
- **Operating System**: Windows, macOS, or Linux
- **Hardware**: Minimal requirements for 3D maze rendering

## Installation & Setup

### 1. Clone or Download the Project
```bash
git clone https://github.com/Easibaja/Maze_CC.git
cd Maze_CC
```

### 2. Open in Godot Engine
- Launch Godot Engine 4.0+
- Click "Import" and navigate to the project folder
- Select `project.godot` to open the project

### 3. Run the Project
- Press `F5` or click the "Run Project" button
- The main menu should load

## Usage

### Starting an Experiment Session

1. Launch the game from the Main Menu
2. Choose a maze generation algorithm to test
3. Navigate through the generated maze to reach the checkpoint
4. Complete the maze and provide feedback on motivation and cognitive load

### Game Controls

- **WASD / Arrow Keys**: Move character
- **Shift**: Toggle run
- **ESC**: Return to menu

### Data Collection

The application automatically collects:
- Movement heatmaps showing player navigation patterns
- Time taken to complete each maze
- Player interaction patterns
- In-game performance metrics

## Key Game Systems

### Maze Generation (`scripts/maze/`)
- **MazeGenerator.gd**: Core algorithm implementation
- **TextureGenerator.gd**: Dynamic texture creation for maze visualization

### Tracking System (`scripts/systems/`)
- **HeatmapTracker.gd**: Records player positions and movement patterns

### Environment (`scenes/environment/`)
- **Floor3D.tscn**: Procedurally textured floor
- **Wall3D.tscn**: Procedurally textured walls
- **Checkpoint.tscn**: Goal waypoint for maze completion

### Player & Characters (`scenes/player/`)
- **Player.tscn**: Main player entity
- **May.tscn** / **MayCharacter.tscn**: May character with animations
- **MayAnimations.gd**: Animation state machine

## Research Methodology

### Data Analysis Variables

- **Intrinsic Motivation**: Measured through engagement metrics and player self-report
- **Cognitive Workload**: Assessed via perceived difficulty rating and task completion time
- **Movement Patterns**: Analyzed via heatmap data

### Experimental Design

Each participant is assigned to one of the three maze generation algorithms and experiences:
1. **Level 1 (Easy)**: Complete the maze at easy difficulty
2. **Level 2 (Medium)**: Complete the maze at medium difficulty
3. **Level 3 (Hard)**: Complete the maze at hard difficulty
4. **Questionnaires**: Complete post-experiment surveys assessing intrinsic motivation and perceived cognitive workload

**Note:** Participants only play mazes generated with their assigned algorithm across all three difficulty levels to ensure a within-subject comparison of difficulty effects on motivation and workload perception. Every participant will play the same seed.

## Output & Results

The application generates:
- **Performance logs**: Time and efficiency metrics

## Project Configuration

The main project settings are configured in `project.godot`. Key settings include:
- 3D rendering pipeline
- Physics engine configuration
- Input mappings
- Scene defaults

## Contributing & Support

For issues, bug reports, or improvements related to the experiment, please contact the research team.

## License

This project is created for academic research purposes.

## Acknowledgments

Built with Godot Engine - Free and Open Source 2D and 3D game engine.

Character assets from the Godot community and third-party creators.