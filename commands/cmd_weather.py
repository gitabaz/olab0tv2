import requests

WMO_code = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing rime fog",
    51: "Drizzle: light intensity",
    53: "Drizzle: moderate intensity",
    55: "Drizzle: dense intensity",
    56: "Freezing Drizzle: light intensity",
    57: "Freezing Drizzle: dense intensity",
    61: "Rain: slight intensity",
    63: "Rain: moderate intensity",
    65: "Rain: heavy intensity",
    66: "Freezing Rain: light intensity",
    67: "Freezing Rain: heavy intensity",
    71: "Snow fall: slight intensity",
    73: "Snow fall: moderate intensity",
    75:	"Snow fall: heavy intensity",
    77: "Snow grains",
    80: "Rain showers: slight",
    81: "Rain showers: moderate",
    82: "Rain showers: violent",
    85: "Snow showers slight",
    86: "Snow showers heavy",
    95: "Thunderstorm: Slight or moderate",
    96: "Thunderstorm with slight hail",
    99:	"Thunderstorm with heavy hail"
}

wc_to_emoji = {
    0: "☀️",
    1: "🌤️",
    2: "⛅",
    3: "☁️",
    45: "🌫️",
    48: "🌫️",
    51: "🌧️",
    53: "🌧️🌧️",
    55: "🌧️🌧️",
    56: "🌨️",
    57: "🌨️",
    61: "🌧️",
    63: "🌧️🌧️",
    65: "🌧️🌧️🌧️",
    66: "🌨️",
    67: "🌨️",
    71: "❄️",
    73: "❄️❄️",
    75:	"❄️❄️❄️",
    77: "❄️",
    80: "🌧️",
    81: "🌧️🌧️",
    82: "🌧️🌧️🌧️",
    85: "🌨️",
    86: "🌨️❄️🌨️",
    95: "⛈️",
    96: "⛈️❄️❄️",
    99:	"⛈️"
}

def location_to_lat_lon(location):
    r = requests.get(str("https://geocoding-api.open-meteo.com/v1/search?name=%s" % location))
    if r.status_code == 200:
        res = r.json()

        lat = res["results"][0]["latitude"]
        lon = res["results"][0]["longitude"]

        return lat, lon
    else:
        return None

def get_weather(location):
    lat, lon = location_to_lat_lon(location)
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": ["temperature_2m", "weather_code"],
        "temperature_unit": "fahrenheit"
    }

    weather_url = build_weather_url(params)
    r = requests.get(weather_url)

    if r.status_code == 200:
        res = r.json()

        d = {
            "temperature": res["current"]["temperature_2m"],
            "weather_code": res["current"]["weather_code"],
            "unit": res["current_units"]["temperature_2m"]
        }
        str_d = format_weather(d)

        return str_d
    else:
        return None

def format_weather(d):

    return str("%.1f%s %s" % (
        float(d["temperature"]),
        d["unit"],
        wc_to_emoji[int(d["weather_code"])]
    ))

def build_weather_url(params):
    base_url = "https://api.open-meteo.com/v1/forecast?"

    out = base_url
    for k, v in params.items():
        if type(v) == list:
            v = ",".join(v)
        out += str("%s=%s&" % (k, v))

    return out[:-1] # remove extra & at end of string
