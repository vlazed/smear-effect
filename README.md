# Smear Shader <!-- omit from toc -->

Add smears to your props and ragdolls

## Table of Contents <!-- omit from toc -->

- [Description](#description)
  - [Features](#features)
  - [Rational](#rational)
  - [Remarks](#remarks)
- [Disclaimer](#disclaimer)
- [Pull Requests](#pull-requests)
- [Credits](#credits)

## Description

This adds a tool which allows you to equip any prop or ragdoll with a smear effect.

### Features

- **Simple smears**: This adds a smear entity which follows your entity and produces a smear effect
  - This smear effect is simple
- **Customizable smears**: Customize smear noise scale, noise height, lag, and color!
- **Controllable smears**: Smear can be bound and controlled by a key
- **Save/dupe support**: If enabled, smears can be saved or transferred by dupes

### Rational

Smears are an alternative to effects such as motion blur. Particularly for animation, smears help improve the dynamics of a subject's motion.

For GMod animations (using Stop Motion Helper), smears can only be achieved manually by using smear props ([example](https://steamcommunity.com/sharedfiles/filedetails/?id=2775163239)). While these props have served animators, these smears can only be placed at the conclusion of an animation: typically a post-processing step. A situation may call for multiple smears props, which must be keyframed to appear and disappear for specific motions.

This tool makes a smear entity that automatically creates a smear whenever there is motion. This may reduce additional work in making smears for general translational motions.

### Remarks

This shader is adapted from the following implementation:

- https://github.com/cjacobwade/HelpfulScripts/blob/master/SmearEffect/Smear.shader

The entity's translational movement makes smears. Rotation does not generate any smears.

## Disclaimer

## Pull Requests

When making a pull request, make sure to confine to the style seen throughout. Try to add types for new functions or data structures. I used the default [StyLua](https://github.com/JohnnyMorganz/StyLua) formatting style.

## Credits

- The following websites for the smear shader
  - [cjacobwade's HelpfulScripts repo, which contains the smear shader](https://github.com/cjacobwade/HelpfulScripts/blob/master/SmearEffect/Smear.shader)
