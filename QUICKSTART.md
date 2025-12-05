# SimuLift - Quick Start Guide

## 🚀 Getting Started

### Prerequisites
- MATLAB R2019b or newer
- Simulink (no additional toolboxes required)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/GianluigiRiccardi/SimuLift.git
   cd SimuLift
   ```

2. **Open MATLAB** and navigate to the SimuLift directory

3. **You're ready to go!** Choose one of the methods below:

---

## 📊 Usage Methods

### Method 1: Simulink Model (Interactive)
Open the Simulink model directly:
```matlab
open_system('Simulift/SimuLift.slx')
```
or
```matlab
open_system('SimuLift (4).slx')
```

Modify the constant blocks and run the simulation using the ▶️ button.

### Method 2: Automated Scripts (Recommended)

#### Run with Default Settings
```matlab
run_simulift()
```

#### Run Predefined Scenarios
```matlab
run_simulift('scenario', 'light_load')    % Light load, calm conditions
run_simulift('scenario', 'heavy_load')    % Heavy industrial load
run_simulift('scenario', 'heavy_wind')    % High wind conditions
run_simulift('scenario', 'critical')      % Critical multi-risk scenario
```

#### Run with Custom Configuration
```matlab
config = struct(...
    'Theoretical_Weight', 2000, ...
    'Pulley_Weight', 40, ...
    'Slings_Weight', 25, ...
    'Safety_Factor', 1.3, ...
    'Height', 2, ...
    'Deformation_Limit', 0.2, ...
    'Beaufort_Scale', 5, ...
    'Exposed_Area', 1.5, ...
    'Crane_Capacity', 4000);

run_simulift('config', config);
```

### Method 3: Safety Analysis (No Simulation)

Generate safety reports without running Simulink:

```matlab
% Create configuration
config = struct(...
    'Theoretical_Weight', 3000, ...
    'Pulley_Weight', 50, ...
    'Slings_Weight', 30, ...
    'Safety_Factor', 1.25, ...
    'Height', 2, ...
    'Deformation_Limit', 0.2, ...
    'Beaufort_Scale', 6, ...
    'Exposed_Area', 1.5, ...
    'Crane_Capacity', 5000);

% Generate report
report = SimuLiftUtils.generate_safety_report(config);
SimuLiftUtils.print_report(report);
```

---

## 🧪 Testing and Examples

### Run Validation Tests
```matlab
test_simulift()
```

This runs a comprehensive test suite including:
- Safe light load scenario
- Overload detection
- High wind conditions
- Impact force calculations
- Beaufort scale conversions
- Critical multi-risk scenarios

### Run Examples
```matlab
examples
```

This demonstrates:
- Basic usage patterns
- Light and heavy load analysis
- Wind impact comparisons
- Impact force calculations
- Safety factor effects
- Real-world scenarios
- Batch analysis

---

## 🔧 Utility Functions

### Calculate Impact Force
```matlab
force_n = SimuLiftUtils.calculate_impact_force(mass, height, deformation);
force_kgf = SimuLiftUtils.newtons_to_kgf(force_n);
```

### Check for Overload
```matlab
is_safe = SimuLiftUtils.check_overload(load_mass, crane_capacity, safety_factor);
```

### Wind Analysis
```matlab
wind_speed = SimuLiftUtils.beaufort_to_wind_speed(beaufort_scale);
wind_force = SimuLiftUtils.calculate_wind_force(wind_speed, area);
description = SimuLiftUtils.get_beaufort_description(beaufort_scale);
```

---

## 📋 Configuration Parameters

| Parameter | Description | Unit | Typical Range |
|-----------|-------------|------|---------------|
| `Theoretical_Weight` | Payload mass | kg | 100 - 10000 |
| `Pulley_Weight` | Pulley system mass | kg | 10 - 200 |
| `Slings_Weight` | Sling mass | kg | 5 - 100 |
| `Safety_Factor` | Load multiplier | - | 1.1 - 2.0 |
| `Height` | Drop height | m | 0.5 - 10 |
| `Deformation_Limit` | Stop distance | m | 0.01 - 0.5 |
| `Beaufort_Scale` | Wind force | - | 0 - 12 |
| `Exposed_Area` | Surface area | m² | 0.5 - 10 |
| `Crane_Capacity` | Max capacity | kg | 500 - 50000 |

---

## 📈 Example Outputs

### Safety Report Example
```
╔════════════════════════════════════════════╗
║    SimuLift - Safety Analysis Report      ║
╚════════════════════════════════════════════╝

LOAD ANALYSIS:
  Total Mass:        3080.00 kg
  Effective Load:    3850.00 kg
  Load Ratio:        77.0%
  Overload Safe:     ✅ YES

IMPACT ANALYSIS:
  Impact Force:      302342.40 N (30831.00 kgf)

WIND ANALYSIS:
  Beaufort:          Strong breeze
  Wind Speed:        12.58 m/s (45.28 km/h)
  Wind Force:        145.52 N

OVERALL VERDICT:
  Risk Level:        MEDIUM - Moderate load
  Safe to Lift:      ✅ YES

════════════════════════════════════════════
```

---

## 🎯 Common Scenarios

### Scenario 1: Daily Operations
```matlab
run_simulift('scenario', 'light_load')
```
- Typical maintenance lifts
- Good weather conditions
- Standard safety margins

### Scenario 2: Heavy Industrial
```matlab
run_simulift('scenario', 'heavy_load')
```
- Large equipment installation
- Requires high capacity cranes
- Enhanced safety protocols

### Scenario 3: Adverse Weather
```matlab
run_simulift('scenario', 'heavy_wind')
```
- Wind speed > 20 m/s
- Additional safety considerations
- May require lift postponement

---

## 📚 Additional Resources

- [Full Documentation](README.md)
- [Technical Details](README_SimuLift.md)
- [GitHub Page](https://gianluigiriccardi.github.io/SimuLift/)
- [MATLAB Simulink Docs](https://www.mathworks.com/help/simulink/)
- [Beaufort Scale](https://en.wikipedia.org/wiki/Beaufort_scale)
- [OSHA Crane Standards](https://www.osha.gov/cranes-derricks)

---

## ⚠️ Safety Notice

**This is a simulation tool for educational and planning purposes.**

- Always follow official safety regulations
- Consult certified engineers for real operations
- Local codes and standards take precedence
- Weather conditions can change rapidly
- Equipment must be properly inspected

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

---

## 👤 Author

**Gianluigi Riccardi**
- LinkedIn: [gianluigi-riccardi-ai-industrial](https://www.linkedin.com/in/gianluigi-riccardi-ai-industrial/)
- GitHub: [@GianluigiRiccardi](https://github.com/GianluigiRiccardi)
