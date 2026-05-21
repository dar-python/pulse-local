<?php

namespace App\Data;

readonly class ResolvedWeatherData
{
    public function __construct(
        public string $category,
        public ?string $conditionText,
        public ?int $conditionCode,
        public ?float $temperatureC,
        public ?float $precipMm,
        public string $source,
        public string $observedAt,
        public float $latitude,
        public float $longitude,
    ) {}

    public static function fromArray(array $payload): self
    {
        return new self(
            category: (string) ($payload['category'] ?? 'clear'),
            conditionText: isset($payload['condition_text'])
                ? (string) $payload['condition_text']
                : null,
            conditionCode: isset($payload['condition_code'])
                ? (int) $payload['condition_code']
                : null,
            temperatureC: isset($payload['temperature_c'])
                ? (float) $payload['temperature_c']
                : null,
            precipMm: isset($payload['precip_mm'])
                ? (float) $payload['precip_mm']
                : null,
            source: (string) ($payload['source'] ?? 'fallback'),
            observedAt: (string) ($payload['observed_at'] ?? now()->toIso8601String()),
            latitude: (float) ($payload['latitude'] ?? config('services.weatherapi.default_latitude', 14.5995)),
            longitude: (float) ($payload['longitude'] ?? config('services.weatherapi.default_longitude', 120.9842)),
        );
    }

    public function withSource(string $source): self
    {
        return new self(
            category: $this->category,
            conditionText: $this->conditionText,
            conditionCode: $this->conditionCode,
            temperatureC: $this->temperatureC,
            precipMm: $this->precipMm,
            source: $source,
            observedAt: $this->observedAt,
            latitude: $this->latitude,
            longitude: $this->longitude,
        );
    }

    public function toArray(): array
    {
        return [
            'category' => $this->category,
            'condition_text' => $this->conditionText,
            'condition_code' => $this->conditionCode,
            'temperature_c' => $this->temperatureC,
            'precip_mm' => $this->precipMm,
            'source' => $this->source,
            'observed_at' => $this->observedAt,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
        ];
    }
}
