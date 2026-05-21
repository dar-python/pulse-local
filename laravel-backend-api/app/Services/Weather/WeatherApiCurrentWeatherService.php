<?php

namespace App\Services\Weather;

use App\Data\ResolvedWeatherData;
use App\Services\FoodPulseLocalData;
use Carbon\CarbonImmutable;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use RuntimeException;
use Throwable;

class WeatherApiCurrentWeatherService implements WeatherServiceInterface
{
    private const CLEAR_CODES = [
        1000,
        1003,
        1006,
        1009,
        1030,
        1135,
        1147,
    ];

    private const RAINY_CODES = [
        1063,
        1072,
        1150,
        1153,
        1168,
        1171,
        1180,
        1183,
        1186,
        1189,
        1192,
        1195,
        1198,
        1201,
        1240,
        1243,
        1246,
    ];

    private const STORMY_CODES = [
        1087,
        1273,
        1276,
    ];

    private const WINTRY_CODES = [
        1066,
        1069,
        1114,
        1117,
        1204,
        1207,
        1210,
        1213,
        1216,
        1219,
        1222,
        1225,
        1237,
        1249,
        1252,
        1255,
        1258,
        1261,
        1264,
        1279,
        1282,
    ];

    public function __construct(private readonly FoodPulseLocalData $foodPulseData) {}

    public function currentForCheckout(array $checkoutContext): ResolvedWeatherData
    {
        [$latitude, $longitude] = $this->coordinatesFor($checkoutContext);
        $cacheKey = $this->cacheKey($latitude, $longitude);

        $cached = Cache::get($cacheKey);
        if (is_array($cached)) {
            return ResolvedWeatherData::fromArray($cached);
        }

        $apiKey = trim((string) config('services.weatherapi.key', ''));
        if ($apiKey === '') {
            return $this->fallbackWeather($latitude, $longitude);
        }

        try {
            $weather = $this->fetchCurrentWeather($apiKey, $latitude, $longitude);
            $payload = $weather->toArray();

            Cache::put(
                $cacheKey,
                $payload,
                max(1, (int) config('services.weatherapi.cache_ttl_seconds', 600))
            );
            Cache::forever($cacheKey.':stale', $payload);

            return $weather;
        } catch (Throwable $e) {
            Log::warning('WeatherAPI current weather fallback triggered.', [
                'exception_class' => $e::class,
                'cache_key' => $cacheKey,
                'latitude' => $latitude,
                'longitude' => $longitude,
            ]);

            $stale = Cache::get($cacheKey.':stale');
            if (is_array($stale)) {
                return ResolvedWeatherData::fromArray($stale)->withSource('fallback');
            }

            return $this->fallbackWeather($latitude, $longitude);
        }
    }

    private function fetchCurrentWeather(
        string $apiKey,
        float $latitude,
        float $longitude,
    ): ResolvedWeatherData {
        try {
            return $this->requestCurrentWeather($apiKey, $latitude, $longitude);
        } catch (ConnectionException) {
            return $this->requestCurrentWeather($apiKey, $latitude, $longitude);
        }
    }

    private function requestCurrentWeather(
        string $apiKey,
        float $latitude,
        float $longitude,
    ): ResolvedWeatherData {
        $response = Http::baseUrl(rtrim((string) config('services.weatherapi.base_url'), '/'))
            ->acceptJson()
            ->timeout((int) config('services.weatherapi.timeout_seconds', 2))
            ->get('/current.json', [
                'key' => $apiKey,
                'q' => $latitude.','.$longitude,
                'aqi' => 'no',
            ]);

        if ($response->failed()) {
            throw new RuntimeException('WeatherAPI request failed with HTTP '.$response->status().'.');
        }

        $payload = $response->json();
        if (! is_array($payload)) {
            throw new RuntimeException('WeatherAPI response was not valid JSON.');
        }

        return $this->weatherFromPayload($payload, $latitude, $longitude);
    }

    private function weatherFromPayload(
        array $payload,
        float $latitude,
        float $longitude,
    ): ResolvedWeatherData {
        $condition = $payload['current']['condition'] ?? null;
        if (! is_array($condition)) {
            throw new RuntimeException('WeatherAPI response is missing condition data.');
        }

        $conditionCode = isset($condition['code']) && is_numeric($condition['code'])
            ? (int) $condition['code']
            : null;
        $conditionText = isset($condition['text'])
            ? (string) $condition['text']
            : null;

        return new ResolvedWeatherData(
            category: $this->categoryFor($conditionCode, $conditionText),
            conditionText: $conditionText,
            conditionCode: $conditionCode,
            temperatureC: isset($payload['current']['temp_c'])
                ? (float) $payload['current']['temp_c']
                : null,
            precipMm: isset($payload['current']['precip_mm'])
                ? (float) $payload['current']['precip_mm']
                : null,
            source: 'weatherapi',
            observedAt: $this->observedAt($payload),
            latitude: $latitude,
            longitude: $longitude,
        );
    }

    private function categoryFor(?int $conditionCode, ?string $conditionText): string
    {
        $text = Str::lower($conditionText ?? '');

        if ($conditionCode !== null && in_array($conditionCode, self::STORMY_CODES, true)) {
            return 'stormy';
        }

        if (Str::contains($text, ['thunder', 'thunderstorm', 'storm', 'lightning'])) {
            return 'stormy';
        }

        if ($conditionCode !== null && in_array($conditionCode, self::CLEAR_CODES, true)) {
            return 'clear';
        }

        if ($conditionCode !== null && in_array($conditionCode, self::RAINY_CODES, true)) {
            return 'rainy';
        }

        if ($conditionCode !== null && in_array($conditionCode, self::WINTRY_CODES, true)) {
            return 'rainy';
        }

        if (Str::contains($text, ['rain', 'drizzle', 'sleet', 'snow', 'ice', 'freezing'])) {
            return 'rainy';
        }

        return 'clear';
    }

    private function observedAt(array $payload): string
    {
        $timezone = (string) ($payload['location']['tz_id'] ?? config('app.timezone', 'UTC'));
        $epoch = $payload['current']['last_updated_epoch'] ?? null;

        if (is_numeric($epoch)) {
            return CarbonImmutable::createFromTimestamp((int) $epoch, $timezone)
                ->toIso8601String();
        }

        return now($timezone)->toIso8601String();
    }

    private function coordinatesFor(array $checkoutContext): array
    {
        $requestLatitude = $checkoutContext['delivery_latitude'] ?? null;
        $requestLongitude = $checkoutContext['delivery_longitude'] ?? null;

        if (is_numeric($requestLatitude) && is_numeric($requestLongitude)) {
            return [(float) $requestLatitude, (float) $requestLongitude];
        }

        $restaurant = $this->restaurantFor($checkoutContext);
        if (
            is_array($restaurant)
            && is_numeric($restaurant['latitude'] ?? null)
            && is_numeric($restaurant['longitude'] ?? null)
        ) {
            return [(float) $restaurant['latitude'], (float) $restaurant['longitude']];
        }

        return [
            (float) config('services.weatherapi.default_latitude', 14.5995),
            (float) config('services.weatherapi.default_longitude', 120.9842),
        ];
    }

    private function restaurantFor(array $checkoutContext): ?array
    {
        $restaurantId = $checkoutContext['restaurant_id'] ?? null;
        if (is_numeric($restaurantId)) {
            return $this->foodPulseData->restaurant((int) $restaurantId);
        }

        $requestedSlug = $checkoutContext['restaurant_slug'] ?? null;
        if (! is_string($requestedSlug) || trim($requestedSlug) === '') {
            return null;
        }

        $slug = Str::slug($requestedSlug);
        foreach ($this->foodPulseData->restaurants() as $restaurant) {
            if (($restaurant['slug'] ?? Str::slug((string) $restaurant['name'])) === $slug) {
                return $restaurant;
            }
        }

        return null;
    }

    private function cacheKey(float $latitude, float $longitude): string
    {
        return sprintf(
            'weatherapi:current:%s:%s',
            $this->roundedCoordinate($latitude),
            $this->roundedCoordinate($longitude)
        );
    }

    private function roundedCoordinate(float $value): string
    {
        return number_format(round($value, 3), 3, '.', '');
    }

    private function fallbackWeather(float $latitude, float $longitude): ResolvedWeatherData
    {
        return new ResolvedWeatherData(
            category: 'clear',
            conditionText: 'Weather unavailable',
            conditionCode: null,
            temperatureC: null,
            precipMm: null,
            source: 'fallback',
            observedAt: now()->toIso8601String(),
            latitude: $latitude,
            longitude: $longitude,
        );
    }
}
