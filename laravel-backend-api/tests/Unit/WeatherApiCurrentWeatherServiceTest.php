<?php

namespace Tests\Unit;

use App\Services\Weather\WeatherApiCurrentWeatherService;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class WeatherApiCurrentWeatherServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config([
            'services.weatherapi.base_url' => 'https://api.weatherapi.com/v1',
            'services.weatherapi.key' => 'test-weather-key',
            'services.weatherapi.timeout_seconds' => 2,
            'services.weatherapi.cache_ttl_seconds' => 600,
            'services.weatherapi.default_latitude' => 14.5995,
            'services.weatherapi.default_longitude' => 120.9842,
        ]);

        Cache::flush();
    }

    public function test_weatherapi_condition_codes_map_to_model_categories(): void
    {
        $cases = [
            [1000, 'Sunny', 'clear'],
            [1003, 'Partly cloudy', 'clear'],
            [1183, 'Light rain', 'rainy'],
            [1243, 'Moderate or heavy rain shower', 'rainy'],
            [1087, 'Thundery outbreaks possible', 'stormy'],
            [1276, 'Moderate or heavy rain with thunder', 'stormy'],
        ];
        $sequence = Http::sequence();

        foreach ($cases as [$code, $text]) {
            $sequence->push($this->weatherApiPayload($code, $text));
        }

        Http::fake(['*' => $sequence]);

        foreach ($cases as $index => [$code, $text, $expectedCategory]) {
            $weather = app(WeatherApiCurrentWeatherService::class)
                ->currentForCheckout([
                    'delivery_latitude' => 14.5995 + ($index / 100),
                    'delivery_longitude' => 120.9842,
                ]);

            $this->assertSame($expectedCategory, $weather->category, $text);
            $this->assertSame($text, $weather->conditionText);
            $this->assertSame($code, $weather->conditionCode);
            $this->assertSame('weatherapi', $weather->source);
        }
    }

    public function test_weatherapi_failure_uses_stale_cached_weather_when_available(): void
    {
        Cache::put('weatherapi:current:14.600:120.984:stale', [
            'category' => 'rainy',
            'condition_text' => 'Light rain',
            'condition_code' => 1183,
            'temperature_c' => 28.4,
            'precip_mm' => 0.8,
            'source' => 'weatherapi',
            'observed_at' => '2026-05-21T10:30:00+08:00',
            'latitude' => 14.5995,
            'longitude' => 120.9842,
        ]);

        Http::fake(fn () => throw new ConnectionException('Weather timed out.'));

        $weather = app(WeatherApiCurrentWeatherService::class)
            ->currentForCheckout([
                'delivery_latitude' => 14.5995,
                'delivery_longitude' => 120.9842,
            ]);

        $this->assertSame('rainy', $weather->category);
        $this->assertSame('fallback', $weather->source);
        $this->assertSame(1183, $weather->conditionCode);
    }

    public function test_weatherapi_failure_without_cache_uses_neutral_clear_fallback(): void
    {
        Http::fake(fn () => throw new ConnectionException('Weather timed out.'));

        $weather = app(WeatherApiCurrentWeatherService::class)
            ->currentForCheckout([
                'delivery_latitude' => 14.5995,
                'delivery_longitude' => 120.9842,
            ]);

        $this->assertSame('clear', $weather->category);
        $this->assertSame('fallback', $weather->source);
    }

    public function test_coordinate_resolution_uses_delivery_then_merchant_then_default_coordinates(): void
    {
        Http::fake([
            'https://api.weatherapi.com/v1/current.json*' => Http::sequence()
                ->push($this->weatherApiPayload(1000, 'Clear'))
                ->push($this->weatherApiPayload(1000, 'Clear'))
                ->push($this->weatherApiPayload(1000, 'Clear')),
        ]);

        $deliveryWeather = app(WeatherApiCurrentWeatherService::class)
            ->currentForCheckout([
                'restaurant_id' => 2,
                'delivery_latitude' => 12.3456,
                'delivery_longitude' => 123.4567,
            ]);
        $merchantWeather = app(WeatherApiCurrentWeatherService::class)
            ->currentForCheckout(['restaurant_id' => 2]);
        $defaultWeather = app(WeatherApiCurrentWeatherService::class)
            ->currentForCheckout([]);

        $this->assertSame(12.3456, $deliveryWeather->latitude);
        $this->assertSame(123.4567, $deliveryWeather->longitude);
        $this->assertSame(11.2442, $merchantWeather->latitude);
        $this->assertSame(125.003, $merchantWeather->longitude);
        $this->assertSame(14.5995, $defaultWeather->latitude);
        $this->assertSame(120.9842, $defaultWeather->longitude);
    }

    private function weatherApiPayload(int $code, string $text): array
    {
        return [
            'location' => [
                'tz_id' => 'Asia/Manila',
            ],
            'current' => [
                'last_updated_epoch' => 1779330600,
                'temp_c' => 30.2,
                'precip_mm' => 0,
                'condition' => [
                    'text' => $text,
                    'code' => $code,
                ],
            ],
        ];
    }
}
