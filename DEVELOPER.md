# SimuLift - Developer Documentation

## Project Structure

```
SimuLift/
├── Simulift/
│   ├── SimuLift.slx          # Main Simulink model
│   └── img/                   # Icons and images
├── SimuLift (4).slx           # Alternative model file
├── run_simulift.m             # Main automation script
├── SimuLiftUtils.m            # Utility functions class
├── test_simulift.m            # Validation test suite
├── examples.m                 # Usage examples
├── simulift_config_template.m # Configuration templates
├── README.md                  # Main documentation
├── README_SimuLift.md         # Detailed technical docs
├── QUICKSTART.md              # Quick start guide
├── index.md                   # GitHub Pages content
└── .gitignore                 # Git ignore rules
```

## Script Descriptions

### run_simulift.m
Main entry point for running simulations programmatically.

**Features:**
- Predefined scenarios (light_load, heavy_load, heavy_wind, critical)
- Custom configuration support
- Automatic model loading and parameter application
- Results display and reporting

**Usage:**
```matlab
% Run with default parameters
run_simulift()

% Run specific scenario
run_simulift('scenario', 'heavy_wind')

% Run with custom config
config = struct('Theoretical_Weight', 2000, ...);
run_simulift('config', config)
```

### SimuLiftUtils.m
Utility class providing static methods for calculations.

**Methods:**
- `calculate_impact_force(mass, height, deformation)` - Impact force calculation
- `newtons_to_kgf(force_n)` - Unit conversion
- `check_overload(load_mass, crane_capacity, safety_factor)` - Overload check
- `beaufort_to_wind_speed(beaufort_scale)` - Beaufort conversion
- `calculate_wind_force(wind_speed, area, drag_coef)` - Wind force
- `get_beaufort_description(beaufort_scale)` - Wind description
- `generate_safety_report(config)` - Comprehensive safety analysis
- `print_report(report)` - Formatted report output

**Example:**
```matlab
% Calculate impact force
force = SimuLiftUtils.calculate_impact_force(100, 3, 0.15);

% Generate full report
config = struct(...);
report = SimuLiftUtils.generate_safety_report(config);
SimuLiftUtils.print_report(report);
```

### test_simulift.m
Automated test suite for validation.

**Tests:**
1. Safe light load scenario
2. Overload detection
3. High wind conditions
4. Impact force calculations
5. Beaufort scale conversions
6. Critical multi-risk scenarios

**Usage:**
```matlab
test_simulift()  % Runs all tests and displays results
```

### examples.m
Demonstration script with 8 examples.

**Examples:**
1. Default scenario
2. Light load in calm weather
3. Heavy industrial load
4. Wind impact analysis
5. Impact force comparison
6. Safety factor effects
7. Real-world pipe installation
8. Batch analysis

**Usage:**
```matlab
examples()  % Runs all examples
```

### simulift_config_template.m
Template for creating custom configurations.

**Includes:**
- Annotated parameter descriptions
- Example configurations for common scenarios
- Best practices and typical values

**Usage:**
```matlab
config = simulift_config_template();
% Or use predefined configs:
config = config_light_maintenance();
config = config_heavy_industrial();
```

## Physics Formulas

### Impact Force
```
F = (m × g × h) / Δs

Where:
  m = mass (kg)
  g = 9.81 m/s² (gravitational acceleration)
  h = drop height (m)
  Δs = deformation/stopping distance (m)
```

### Wind Speed (Beaufort)
```
v = 0.836 × B^1.5

Where:
  v = wind speed (m/s)
  B = Beaufort scale (0-12)
```

### Wind Force
```
F = 0.5 × ρ × v² × A × Cd

Where:
  ρ = 1.225 kg/m³ (air density)
  v = wind speed (m/s)
  A = exposed area (m²)
  Cd = drag coefficient (default: 1.0)
```

### Overload Check
```
Effective Load = Total Mass × Safety Factor
Is Safe = Effective Load ≤ Crane Capacity
```

## Configuration Parameters

### Required Parameters

| Parameter | Type | Unit | Description |
|-----------|------|------|-------------|
| `Theoretical_Weight` | number | kg | Mass of the payload |
| `Pulley_Weight` | number | kg | Mass of pulley system |
| `Slings_Weight` | number | kg | Mass of slings |
| `Crane_Capacity` | number | kg | Maximum crane capacity (SWL) |
| `Safety_Factor` | number | - | Load multiplier (typical: 1.1-2.0) |
| `Height` | number | m | Potential drop height |
| `Deformation_Limit` | number | m | Impact absorption distance |
| `Beaufort_Scale` | number | - | Wind force scale (0-12) |
| `Exposed_Area` | number | m² | Wind exposure area |

### Typical Ranges

| Parameter | Light | Medium | Heavy | Critical |
|-----------|-------|--------|-------|----------|
| Weight | < 1000 kg | 1000-5000 kg | 5000-10000 kg | > 10000 kg |
| Safety Factor | 1.5-2.0 | 1.3-1.5 | 1.25-1.3 | 1.1-1.25 |
| Beaufort | 0-3 | 3-6 | 6-8 | > 8 |

## Testing Guidelines

### Unit Tests
Run `test_simulift()` to verify:
- Calculation accuracy
- Safety threshold detection
- Edge cases
- Formula correctness

### Integration Tests
For Simulink model testing:
1. Open model in MATLAB
2. Verify block connections
3. Test with known scenarios
4. Compare with calculated values

### Manual Testing
Use `examples()` to:
- Verify realistic scenarios
- Compare results with expectations
- Test edge cases
- Validate reports

## Best Practices

### Code Style
- Use descriptive variable names
- Comment complex calculations
- Keep functions focused and small
- Follow MATLAB naming conventions

### Safety Considerations
- Always use appropriate safety factors
- Consider worst-case scenarios
- Account for environmental conditions
- Verify calculations independently

### Performance
- Pre-allocate arrays when possible
- Vectorize operations
- Minimize Simulink model complexity
- Cache repeated calculations

## Extending the Code

### Adding New Scenarios
1. Define configuration in `run_simulift.m`
2. Add to scenario switch case
3. Test with validation suite
4. Document in QUICKSTART.md

### Adding New Calculations
1. Add static method to `SimuLiftUtils`
2. Include formula documentation
3. Add unit test in `test_simulift.m`
4. Provide usage example

### Custom Reports
1. Extend `generate_safety_report()`
2. Add new metrics to report structure
3. Update `print_report()` for display
4. Document new fields

## Troubleshooting

### Common Issues

**Issue: Model not found**
- Check file path is correct
- Verify model file exists
- Use absolute path if needed

**Issue: Parameter not applied**
- Verify block name matches parameter
- Check model structure
- Ensure model is loaded

**Issue: Calculation errors**
- Verify input units
- Check for division by zero
- Validate parameter ranges

## Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new features
4. Update documentation
5. Submit pull request

## License

MIT License - See LICENSE file for details

## Author

Gianluigi Riccardi
- LinkedIn: [gianluigi-riccardi-ai-industrial](https://www.linkedin.com/in/gianluigi-riccardi-ai-industrial/)
- GitHub: [@GianluigiRiccardi](https://github.com/GianluigiRiccardi)

## Version History

**v1.1** (Current)
- Added automation scripts
- Included utility functions
- Created test suite
- Added examples and documentation

**v1.0**
- Initial Simulink model
- Basic documentation
- GitHub Pages setup
