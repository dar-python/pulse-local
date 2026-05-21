<?php

namespace App\Services;

use Illuminate\Support\Str;

class CheckoutPredictionFeatureBuilder
{
    private const RESTAURANT_PROFILES = [
        'tambayan-grill' => [
            'base_distance_km' => 4.2,
            'base_prep_time' => 25,
            'traffic' => 'medium',
            'vehicle_type' => 'motorcycle',
            'courier_experience_yrs' => 2.0,
        ],
        'jollibee-express' => [
            'base_distance_km' => 2.8,
            'base_prep_time' => 15,
            'traffic' => 'low',
            'vehicle_type' => 'motorcycle',
            'courier_experience_yrs' => 3.5,
        ],
        'chao-fan-house' => [
            'base_distance_km' => 5.8,
            'base_prep_time' => 30,
            'traffic' => 'high',
            'vehicle_type' => 'motorcycle',
            'courier_experience_yrs' => 1.0,
        ],
    ];

    public function __construct(private readonly FoodPulseLocalData $foodPulseData) {}

    public function build(array $checkoutContext, string $weatherCategory = 'clear'): array
    {
        $profile = $this->profileFor($checkoutContext);
        $items = $checkoutContext['items'] ?? [];
        $totalQuantity = $this->totalQuantity($checkoutContext);
        $preparationTime = (int) $profile['base_prep_time']
            + $this->quantityPreparationAdjustment($totalQuantity)
            + $this->categoryPreparationAdjustment($items);
        $distance = (float) $profile['base_distance_km']
            + $this->addressDistanceAdjustment($checkoutContext['delivery_address'] ?? []);

        return [
            'Distance_km' => round($distance, 1),
            'Weather' => $this->normalizeWeatherCategory($weatherCategory),
            'Traffic_Level' => $profile['traffic'],
            'Time_of_Day' => $this->timeOfDay(),
            'Vehicle_Type' => $profile['vehicle_type'],
            'Preparation_Time_min' => $preparationTime,
            'Courier_Experience_yrs' => (float) $profile['courier_experience_yrs'],
        ];
    }

    private function profileFor(array $checkoutContext): array
    {
        $slug = $this->restaurantSlug($checkoutContext);

        return self::RESTAURANT_PROFILES[$slug]
            ?? self::RESTAURANT_PROFILES['tambayan-grill'];
    }

    private function restaurantSlug(array $checkoutContext): string
    {
        $requestedSlug = $checkoutContext['restaurant_slug'] ?? null;
        if (is_string($requestedSlug) && trim($requestedSlug) !== '') {
            return Str::slug($requestedSlug);
        }

        $restaurantId = (int) ($checkoutContext['restaurant_id'] ?? 0);
        $restaurant = $restaurantId > 0
            ? $this->foodPulseData->restaurant($restaurantId)
            : null;

        return Str::slug((string) ($restaurant['name'] ?? 'tambayan-grill'));
    }

    private function totalQuantity(array $checkoutContext): int
    {
        if (isset($checkoutContext['total_quantity']) && is_numeric($checkoutContext['total_quantity'])) {
            return (int) $checkoutContext['total_quantity'];
        }

        return array_sum(array_map(
            fn (array $item): int => (int) ($item['quantity'] ?? 0),
            $checkoutContext['items'] ?? []
        ));
    }

    private function quantityPreparationAdjustment(int $totalQuantity): int
    {
        if ($totalQuantity >= 5) {
            return 10;
        }

        if ($totalQuantity >= 3) {
            return 5;
        }

        return 0;
    }

    private function categoryPreparationAdjustment(array $items): int
    {
        $categoryAdjustments = [
            'mains' => 3,
            'rice meals' => 3,
            'noodles' => 3,
            'specials' => 5,
        ];

        $adjustment = 0;

        foreach ($items as $item) {
            if (! is_array($item)) {
                continue;
            }

            $category = Str::lower((string) ($item['category'] ?? ''));
            $adjustment = max($adjustment, $categoryAdjustments[$category] ?? 0);
        }

        return $adjustment;
    }

    private function addressDistanceAdjustment(array $deliveryAddress): float
    {
        $addressText = Str::lower(implode(' ', array_filter([
            $deliveryAddress['label'] ?? '',
            $deliveryAddress['notes'] ?? '',
        ])));

        foreach (['zone', 'purok', 'sitio', 'extension', 'subdivision', 'barangay', 'brgy'] as $marker) {
            if (str_contains($addressText, $marker)) {
                return 0.8;
            }
        }

        return 0.0;
    }

    private function normalizeWeatherCategory(string $weatherCategory): string
    {
        $category = Str::lower(trim($weatherCategory));

        return in_array($category, ['clear', 'rainy', 'stormy'], true)
            ? $category
            : 'clear';
    }

    private function timeOfDay(): string
    {
        $hour = now()->hour;

        if ($hour >= 5 && $hour <= 11) {
            return 'morning';
        }

        if ($hour >= 12 && $hour <= 16) {
            return 'afternoon';
        }

        if ($hour >= 17 && $hour <= 20) {
            return 'evening';
        }

        return 'night';
    }
}
