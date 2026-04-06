# Invasiones

A strategy game about the English invasions of Argentina, originally developed in C# as a Windows desktop game for my graduation project at [UNLAM](https://www.unlam.edu.ar/) (Universidad Nacional de La Matanza), Argentina. I graduated as an Informatics Engineer in December 2008.

As part of the course requirements, the entire codebase and documentation had to be written in Spanish.

The original project was hosted in an SVN repository on Assembla, so the development history has been lost.

## Gameplay

The player commands Argentine units across tile-based maps during the British Invasions of the Río de la Plata (1806–1807). Each level is divided into battles, and each battle into a sequence of objectives: moving units to key positions, capturing objects, eliminating enemies, or triggering events. The enemy faction is controlled by an AI that issues its own orders per battle.

## Features

- Tile-based map with scrolling camera and XML-defined levels
- Pathfinding for unit movement
- Unit behaviors: move, patrol, heal, engage
- AI-controlled enemy groups with scripted battle orders
- Episode/battle/objective progression system
- Sprite animations, sound effects, and a GUI with menus, help, and options screens

## Architecture

Built from scratch in C# (~18,000 lines) without a game engine. Core systems include:

- **State machine** driving unit and game screen logic
- **Resource manager** for sprites, fonts, sounds, and animations
- **XML loader** for levels, objectives, and AI orders
- **Partial classes** for the main `Episodio` (episode) logic, split across loading, intro, and gameplay states

