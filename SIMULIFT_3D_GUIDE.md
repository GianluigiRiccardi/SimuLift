# SimuLift 3D - Simscape Multibody Integration Guide

## Overview

SimuLift 3D extends the original 2D SimuLift safety model with a full three-dimensional physics simulation using MATLAB Simscape Multibody. This enables realistic visualization of:

- Dynamic payload motion
- Cable/sling behavior under load
- Wind force effects on swinging payloads
- Multi-body interactions
- Real-time 3D animation

## Quick Start

### Running 3D Simulations

```matlab
% Basic 3D simulation (after creating the model)
run_simulift('Scenario', 'heavy_load', 'Use3D', true)

% Or use directly
run_simulift_3D('scenario', 'heavy_load')

% Custom configuration
config = get_default_3D_config();
config.Payload_Length = 3.0;
config.Wind_Speed = 15;
run_simulift_3D('config', config)
```

## Model Components

### Required Simscape Multibody Blocks

The 3D model (`SimuLift_3D.slx`) should contain:

#### 1. World Frame & Configuration
- **Mechanism Configuration** block
  - Gravity: `[0; 0; -9.81]` m/s²
  - Solver: Variable-step (ode45 or ode15s)

#### 2. Crane Hook System
- **Rigid Transform** block (fixed crane position)
  - Position: `[0; 0; initial_height]` from workspace
- **Brick Solid** or custom geometry
  - Mass: `hook_mass` from workspace
  - Dimensions: Small (e.g., 0.1 × 0.1 × 0.2 m)

#### 3. Sling System

**Option A - Flexible Cable (Recommended):**
- **Cable** block from Simscape Multibody
  - Length: `sling_length` (workspace variable)
  - Stiffness: `sling_stiffness` (workspace variable)
  - Damping: `sling_damping` (workspace variable)

**Option B - Rigid Links:**
- Multiple **Cylindrical Solid** blocks
- Connected with **Revolute Joints**
- Total mass: `sling_mass`

#### 4. Payload
- **Brick Solid** block
  - Dimensions: `[payload_length, payload_width, payload_height]`
  - Mass: `payload_mass` OR
  - Density: `payload_density` (auto-calculated)
  - Color/Appearance: Configurable for visualization

#### 5. Joints
- **Hook → Sling**: Spherical Joint
  - Allows free swinging in all directions
- **Sling → Payload**: Universal or Spherical Joint
  - Enables payload rotation

#### 6. Wind Force
- **External Force & Torque** block
  - Applied to payload frame
  - Force magnitude calculated via MATLAB Function:
    ```matlab
    F_wind = 0.5 * air_density * wind_speed^2 * exposed_area * drag_coefficient
    ```
  - Direction: `[1; 0; 0]` (horizontal, X-axis)

#### 7. Sensors (Optional)
- **Transform Sensor**: Track payload position/orientation
- **Joint Sensor**: Monitor cable tensions
- **Force Sensor**: Measure constraint forces

#### 8. Visualization
- Add colors to Solid blocks
- Configure Mechanics Explorer
- Set frame markers for clarity

## Workspace Variables

All parameters are set automatically by `run_simulift_3D.m`:

### Payload Parameters
```matlab
payload_mass       % kg - Total payload mass
payload_length     % m - X-dimension
payload_width      % m - Y-dimension  
payload_height     % m - Z-dimension
payload_density    % kg/m³ - Calculated from mass/volume
```

### Lifting System
```matlab
hook_mass          % kg - Hook/attachment point mass
sling_mass         % kg - Total sling mass
sling_length       % m - Cable length
sling_stiffness    % N/m - Cable spring constant
sling_damping      % N/(m/s) - Cable damping coefficient
```

### Environmental
```matlab
wind_speed         % m/s - Calculated from Beaufort scale
beaufort_scale     % - Wind force scale (0-12)
exposed_area       % m² - Area facing wind
drag_coefficient   % - Aerodynamic drag (typically 1.0-1.5)
air_density        % kg/m³ - Standard: 1.225
```

### Simulation
```matlab
initial_height     % m - Starting vertical position
safety_factor      % - Load multiplier
gravity            % [0; 0; -9.81] m/s²
```

## Configuration Examples

### Light Load - Calm Conditions
```matlab
config_light = struct(...
    'Theoretical_Weight', 500, ...
    'Payload_Length', 1.0, ...
    'Payload_Width', 0.8, ...
    'Payload_Height', 0.6, ...
    'Hook_Mass', 20, ...
    'Sling_Length', 2.0, ...
    'Sling_Stiffness', 8000, ...
    'Sling_Damping', 80, ...
    'Beaufort_Scale', 3, ...
    'Simulation_Time', 10);
```

### Heavy Load - Moderate Wind
```matlab
config_heavy = struct(...
    'Theoretical_Weight', 8000, ...
    'Payload_Length', 3.0, ...
    'Payload_Width', 2.0, ...
    'Payload_Height', 1.5, ...
    'Hook_Mass', 100, ...
    'Sling_Length', 4.0, ...
    'Sling_Stiffness', 15000, ...
    'Sling_Damping', 150, ...
    'Beaufort_Scale', 6, ...
    'Simulation_Time', 15);
```

### High Wind Scenario
```matlab
config_wind = struct(...
    'Theoretical_Weight', 2000, ...
    'Payload_Length', 2.5, ...
    'Payload_Width', 2.0, ...
    'Payload_Height', 0.8, ...  % Flat panel - high drag
    'Drag_Coefficient', 1.5, ...
    'Beaufort_Scale', 9, ...    % Strong gale
    'Exposed_Area', 2.5, ...
    'Simulation_Time', 12);
```

## Building the Model

### Step-by-Step Guide

1. **Create New Model**
   ```matlab
   new_system('SimuLift_3D')
   open_system('SimuLift_3D')
   ```

2. **Add Mechanism Configuration**
   - Library: Simscape > Multibody > Frames and Transforms
   - Set Gravity: `[0; 0; -9.81]`

3. **Create World Frame**
   - Add World Frame block
   - This serves as the reference

4. **Build Hook Assembly**
   ```
   World Frame → Rigid Transform (fixed position)
                 ↓
               Brick Solid (hook body)
   ```

5. **Add Sling**
   ```
   Hook → Spherical Joint → Cable Block → Payload
   ```

6. **Create Payload**
   - Add Brick Solid
   - Set dimensions from workspace variables
   - Add visual properties

7. **Apply Wind Force**
   ```
   MATLAB Function → External Force & Torque → Payload
   ```
   MATLAB Function code:
   ```matlab
   function F = wind_force(wind_speed, area, cd, rho)
       F_mag = 0.5 * rho * wind_speed^2 * area * cd;
       F = [F_mag; 0; 0];  % Horizontal force
   end
   ```

8. **Add Sensors**
   - Transform Sensor on payload
   - Output to scope/logger

9. **Configure Solver**
   - Model Configuration Parameters
   - Solver: Variable-step, ode45
   - Stop time: `Simulation_Time` variable

### Model Template Structure

```
SimuLift_3D.slx
├── Mechanism Configuration
├── World Frame
├── Crane System
│   ├── Rigid Transform (fixed height)
│   └── Hook Body (Brick Solid)
├── Sling System
│   ├── Spherical Joint (hook connection)
│   ├── Cable/Rigid Links
│   └── Universal Joint (payload connection)
├── Payload
│   └── Brick Solid (parameterized)
├── Wind Force
│   ├── MATLAB Function (force calculation)
│   └── External Force & Torque
└── Sensors
    ├── Transform Sensor (position/orientation)
    └── Scopes/Loggers
```

## Integration with Existing Code

### Automatic Detection

The `run_simulift.m` function automatically switches to 3D mode when `Use3D` is set:

```matlab
% These are equivalent
run_simulift('Scenario', 'heavy_load', 'Use3D', true)
run_simulift('scenario', 'heavy_load', 'use3d', true)  % case-insensitive
```

### Parameter Mapping

| 2D Parameter | 3D Usage | Notes |
|--------------|----------|-------|
| `Theoretical_Weight` | `payload_mass` | Direct mapping |
| `Height` | `initial_height` | Starting Z-position |
| `Beaufort_Scale` | `wind_speed` | Converted automatically |
| `Exposed_Area` | `exposed_area` | Used in wind force |
| `Pulley_Weight` | Not used | Replaced by `hook_mass` |
| `Slings_Weight` | `sling_mass` | Direct mapping |

### New 3D-Only Parameters

- `Payload_Length`, `Payload_Width`, `Payload_Height` - 3D geometry
- `Sling_Stiffness`, `Sling_Damping` - Dynamic properties
- `Drag_Coefficient` - Aerodynamic property
- `Simulation_Time` - Duration

## Physics & Formulas

### Wind Force
```matlab
F_wind = 0.5 * ρ * A * C_d * v²
```
Where:
- ρ = air density (1.225 kg/m³)
- A = exposed area (m²)
- C_d = drag coefficient (1.0-1.5)
- v = wind speed (m/s)

### Cable Dynamics
```matlab
F_cable = k * Δx + c * v
```
Where:
- k = stiffness (N/m)
- Δx = extension from rest length
- c = damping coefficient (N/(m/s))
- v = relative velocity

### Impact Force (from 2D model)
```matlab
F_impact = (m * g * h) / Δs
```

## Visualization

### Mechanics Explorer
- Opens automatically when simulation runs
- Real-time 3D animation
- Rotate/zoom/pan controls
- Frame markers and traces

### Plot Results
```matlab
% After simulation
simOut = run_simulift_3D('scenario', 'heavy_load');

% Extract logged signals
% (requires proper signal logging in model)
time = simOut.tout;
% position = simOut.yout{...}.Values;  % Configure in model
```

## Testing

### Validate 3D Setup
```matlab
% Test without simulation (just configuration)
run_simulift_3D('scenario', 'default', 'simulate', false)

% This creates instruction file without needing the model
```

### Run 3D Examples
```matlab
% Comprehensive demonstrations
examples_3D
```

## Troubleshooting

### Common Issues

1. **Model Not Found**
   ```
   Solution: Create SimuLift_3D.slx following the guide above,
   or run with simulate=false to get instructions
   ```

2. **Workspace Variables Not Set**
   ```
   Solution: Ensure all blocks reference workspace variables,
   not hardcoded values
   ```

3. **Solver Errors**
   ```
   Solution: Try ode15s instead of ode45 for stiff systems
   Increase solver tolerance if needed
   ```

4. **Wind Force Not Applied**
   ```
   Solution: Verify External Force block is connected to
   payload frame, not world frame
   ```

## Performance Tips

- Use larger time steps for faster simulation
- Reduce `Simulation_Time` during development
- Simplify geometry for initial testing
- Use rigid links instead of cables for speed

## Comparison: 2D vs 3D

| Aspect | 2D Model | 3D Model |
|--------|----------|----------|
| Speed | Very fast | Slower (physics simulation) |
| Accuracy | Formulas | Full dynamics |
| Visualization | Text/plots | 3D animation |
| Wind | Simple force | Directional, dynamic |
| Cable | Not modeled | Full dynamics |
| Use Case | Quick checks | Detailed analysis |

## Next Steps

1. **Create the Model**: Follow the step-by-step guide
2. **Test with Scenarios**: Use predefined configurations
3. **Customize**: Adjust parameters for your use case
4. **Validate**: Compare with 2D safety checks
5. **Visualize**: Use Mechanics Explorer for insights

## Examples

See `examples_3D.m` for comprehensive demonstrations of:
- Basic 3D usage
- Different payload geometries
- Wind effect analysis
- Sling stiffness comparison
- Safety recommendations

## References

- [Simscape Multibody Documentation](https://www.mathworks.com/help/sm/)
- [Cable Modeling Guide](https://www.mathworks.com/help/sm/ug/model-flexible-cables.html)
- [Aerodynamic Forces](https://www.mathworks.com/help/sm/ug/model-aerodynamic-forces.html)

---

**Author**: Gianluigi Riccardi  
**Version**: 1.0  
**Date**: December 2025
