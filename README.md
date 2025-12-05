# Simulift

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![MATLAB](https://img.shields.io/badge/Made%20with-MATLAB-blue)
![Last Commit](https://img.shields.io/github/last-commit/GianluigiRiccardi/SimuLift)
![Repo Size](https://img.shields.io/github/repo-size/GianluigiRiccardi/SimuLift)


**Predictive Safety Model for Lifting Operations**  
Built in MATLAB Simulink – created by [Gianluigi Riccardi](https://www.linkedin.com/in/gianluigiriccardi)

![Simulift](https://gianluigiriccardi.github.io/SimuLift/Simulift.png)

---

## 🚀 Overview

**Simulift** is a predictive safety tool designed to simulate real lifting conditions using physics-based logic.  
It checks whether a lift is safe by evaluating:

- **Impact force** (from drop height & deformation)
- **Overload** (mass vs crane capacity with safety factor)
- **Wind force** (based on Beaufort scale)

Final verdicts like ✅ **Safe to Lift** or ❌ **Overload Detected** are clearly shown via visual displays.

---

## 📦 Download & Quick Start

<a href="https://github.com/GianluigiRiccardi/SimuLift/raw/main/SimuLift%20(4).slx" download>
  <button>Download SimuLift (4).slx</button>
</a>

**New!** 🎉 **Automated Scripts Available**

SimuLift now includes MATLAB automation scripts for easier usage:
- **`run_simulift.m`** - Main entry point with predefined scenarios
- **`SimuLiftUtils.m`** - Utility functions for calculations
- **`test_simulift.m`** - Validation test suite
- **`examples.m`** - Usage examples and demonstrations

See [QUICKSTART.md](QUICKSTART.md) for detailed usage instructions.

### Quick Usage
```matlab
% Run with default scenario
run_simulift()

% Run predefined scenarios
run_simulift('scenario', 'light_load')
run_simulift('scenario', 'heavy_wind')

% Run 3D simulation (requires SimuLift_3D.slx)
run_simulift('Scenario', 'heavy_load', 'Use3D', true)

% Run validation tests
test_simulift()
test_simulift_3D()  % Test 3D functionality
```

---

## 📊 Example Scenario

Lifting a 3000 kg payload during wind force 6 (Beaufort):

- Set slings, pulley, and load weight
- Apply deformation limit: 0.2 m  
- Safety Factor: 1.25  
- Exposed area: 1.5 m²

Run the model and observe the visual verdict.

---

### ⚠️ Impact Force – Engineering Note

The impact force is calculated using the simplified physics formula:
F = (m · g · h) / Δs

Where:  
- `m` = mass of the object  
- `g` = gravitational acceleration  
- `h` = drop height  
- `Δs` = deformation or stop distance

This formula estimates the **maximum instantaneous force** transmitted during an impact.

Even a **40 kg pipe falling from 2 meters** with only **1 cm of deformation** can generate:

F = (40 · 9.81 · 2) / 0.01 = 78,480 N

That’s **almost 800 kgf**, potentially enough to damage another pipe, especially if the contact point is narrow or the material is rigid.

**SimuLift uses this conservative approach** to highlight real industrial risks often underestimated during field operations.

---

## 🔧 Parameters You Can Modify

| Parameter            | Block Name            | Affects                         |
|---------------------|------------------------|---------------------------------|
| Payload              | `Theoretical_Weight`   | Load force                      |
| Pulley               | `Pulley_Weight`        | Total mass                      |
| Slings               | `Slings_Weight`        | Total mass                      |
| Safety Factor        | `Safety_Factor`        | Load * multiplier               |
| Drop Height          | `Height`               | Impact energy                   |
| Deformation limit    | `Deformation_Limit`    | Impact force                    |
| Beaufort Scale       | `Beaufort_Scale`       | Wind speed                      |
| Exposed Area         | `Exposed_Area`         | Wind pressure                   |

---

## 🖥 Output Verdicts

- **OK**
- **Alarm**

| Display Block         | Shows                  |
|-----------------------|------------------------|
| `Impact_Status`       | Impact risk            |
| `Overload_Status`     | Load/capacity risk     |
| `Wind_Status`         | Wind force condition   |
| `FinalVerdict_Display`| Global lift verdict    |

---

## 📚 Resources

- [Quick Start Guide](QUICKSTART.md) - Get started quickly with automated scripts
- [Simulink Documentation](https://www.mathworks.com/help/simulink/)
- [Beaufort Wind Scale](https://en.wikipedia.org/wiki/Beaufort_scale)
- [OSHA Crane Lifting Standards](https://www.osha.gov/cranes-derricks)

---

## 🆕 New Features (v1.1)

- **Automated scripts** for programmatic simulation control
- **Predefined scenarios** (light load, heavy load, high wind, critical)
- **Utility functions** for standalone calculations
- **Comprehensive test suite** for validation
- **Example scripts** demonstrating various use cases
- **Safety report generation** with detailed analysis
- **Batch processing** capabilities for multiple scenarios

## 🆕 New Features (v1.2) - 3D Simscape Multibody

- **3D lifting simulation** using Simscape Multibody
- **Full dynamic visualization** with Mechanics Explorer
- **Realistic cable/sling dynamics** with flexible constraints
- **Wind force modeling** with aerodynamic drag
- **Multi-body interactions** for accurate payload motion
- **3D-specific parameters** for geometry and physics
- **Seamless 2D/3D integration** via `Use3D` parameter

---

## 📖 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide with examples
- **[README_SimuLift.md](README_SimuLift.md)** - Detailed technical documentation
- **[SIMULIFT_3D_GUIDE.md](SIMULIFT_3D_GUIDE.md)** - Complete 3D Simscape Multibody guide
- **[examples.m](examples.m)** - Interactive examples and demonstrations
- **[examples_3D.m](examples_3D.m)** - 3D-specific examples and scenarios

---

## 🔄 Changelog

**v1.2 – December 2025**
- 3D Simscape Multibody integration
- Full dynamic simulation with cable/sling physics
- Wind force modeling with aerodynamic drag
- 3D visualization and animation
- Updated documentation and examples

**v1.0 – May 2025**  
- Full predictive model  
- 3 safety subsystems  
- GitHub Pages and documentation added

---

## 🌐 GitHub Page

View the public version of this project:  
https://gianluigiriccardi.github.io/SimuLift/

---

## 🛡️ License

MIT License – use, adapt, and contribute freely.
