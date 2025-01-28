extends Control

@onready var temp_humidity_plot: Graph2D = %TempHumidityPlot
@onready var temp_height_plot: Graph2D = %TempHeightPlot
@onready var humidity_height_plot: Graph2D = %HeightHumidityPlot

var biome_series = {} # Dictionary to store series for each biome

static var min_height = INF
static var max_height = -INF
static var biomes
static var config

static func setup(p_config: TerrainConfig):
	config = p_config
	biomes = config.biomes

	for biome in biomes:
		if biome.height_range.y > max_height:
			max_height = biome.height_range.y
		if biome.height_range.x < min_height:
			min_height = biome.height_range.x

func gen_graph():
	setup_plots()
	visualize_biomes()

func setup_plots():
	# Setup Temperature vs Humidity plot
	temp_humidity_plot.x_label = "Temperature"
	temp_humidity_plot.y_label = "Humidity"
	temp_humidity_plot.x_min = -1.0
	temp_humidity_plot.x_max = 1.0
	temp_humidity_plot.y_min = -1.0
	temp_humidity_plot.y_max = 1.0

	# Setup Temperature vs Height plot
	temp_height_plot.x_label = "Temperature"
	temp_height_plot.y_label = "Height"
	temp_height_plot.x_min = -1.0
	temp_height_plot.x_max = 1.0
	temp_height_plot.y_min = min_height
	temp_height_plot.y_max = max_height

	# Setup Humidity vs Height plot
	humidity_height_plot.x_label = "Humidity"
	humidity_height_plot.y_label = "Height"
	humidity_height_plot.x_min = -1.0
	humidity_height_plot.x_max = 1.0
	humidity_height_plot.y_min = min_height
	humidity_height_plot.y_max = max_height

func visualize_biomes():
	for biome in biomes:
		# Create series for each biome in each plot
		var temp_hum_series = AreaSeries.new(Color(biome.color, 0.3))
		var temp_height_series = AreaSeries.new(Color(biome.color, 0.3))
		var hum_height_series = AreaSeries.new(Color(biome.color, 0.3))

		# Add series to plots
		temp_humidity_plot.add_series(temp_hum_series)
		temp_height_plot.add_series(temp_height_series)
		humidity_height_plot.add_series(hum_height_series)

		# Generate points for Temperature vs Humidity
		var temp_range = biome.temperature_range
		var hum_range = biome.humidity_range
		add_rectangle_points(temp_hum_series,
						   temp_range.x, temp_range.y,
						   hum_range.x, hum_range.y)

		# Generate points for Temperature vs Height
		var height_range = biome.height_range
		add_rectangle_points(temp_height_series,
						   temp_range.x, temp_range.y,
						   height_range.x, height_range.y)

		# Generate points for Humidity vs Height
		add_rectangle_points(hum_height_series,
						   hum_range.x, hum_range.y,
						   height_range.x, height_range.y)

func add_rectangle_points(series: AreaSeries, x_min: float, x_max: float,
						y_min: float, y_max: float):
	# Add points in clockwise order to form a rectangle
	series.add_point(x_min, y_min)
	series.add_point(x_max, y_min)
	series.add_point(x_max, y_max)
	series.add_point(x_min, y_max)
	series.add_point(x_min, y_min) # Close the shape

# Optional: Add a function to visualize current position
func show_current_position(world_x: float, world_z: float):
	var height = TerrainChunk._sample_height(world_x, world_z)
	var humidity = config.humidity.noise.get_noise_2d(world_x, world_z)
	var temperature = config.temperature.noise.get_noise_2d(world_x, world_z)

	# Create or update position indicators
	if not has_node("CurrentPosMarker"):
		var marker_temp_hum = ScatterSeries.new(Color.WHITE, 5.0, ScatterSeries.SHAPE.X)
		var marker_temp_height = ScatterSeries.new(Color.WHITE, 5.0, ScatterSeries.SHAPE.X)
		var marker_hum_height = ScatterSeries.new(Color.WHITE, 5.0, ScatterSeries.SHAPE.X)

		temp_humidity_plot.add_series(marker_temp_hum)
		temp_height_plot.add_series(marker_temp_height)
		humidity_height_plot.add_series(marker_hum_height)

	# Update marker positions
	$CurrentPosMarker/TempHum.clear_points()
	$CurrentPosMarker/TempHeight.clear_points()
	$CurrentPosMarker/HumHeight.clear_points()

	$CurrentPosMarker/TempHum.add_point(temperature, humidity)
	$CurrentPosMarker/TempHeight.add_point(temperature, height)
	$CurrentPosMarker/HumHeight.add_point(humidity, height)
