<?php

namespace Tests\Unit;

use App\Services\CheckoutPredictionFeatureBuilder;
use Carbon\Carbon;
use Tests\TestCase;

class CheckoutPredictionFeatureBuilderTest extends TestCase
{
    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_tambayan_order_builds_tambayan_model_features(): void
    {
        Carbon::setTestNow('2026-05-18 18:15:00');

        $features = app(CheckoutPredictionFeatureBuilder::class)
            ->build($this->payload(
                restaurantId: 1,
                items: [
                    $this->item(1, 'Pork Sinigang', 'Bestsellers', 185, 1),
                    $this->item(2, 'Chicken Inasal', 'Bestsellers', 155, 1),
                ],
                address: [
                    'label' => 'Marasbaras, Tacloban City',
                    'notes' => 'Zone 7, Leyte, Philippines',
                ],
            ));

        $this->assertSame([
            'Distance_km' => 5.0,
            'Weather' => 'rainy',
            'Traffic_Level' => 'medium',
            'Time_of_Day' => 'evening',
            'Vehicle_Type' => 'motorcycle',
            'Preparation_Time_min' => 25,
            'Courier_Experience_yrs' => 2.0,
        ], $features);
    }

    public function test_jollibee_order_builds_jollibee_model_features(): void
    {
        Carbon::setTestNow('2026-05-18 13:30:00');

        $features = app(CheckoutPredictionFeatureBuilder::class)
            ->build($this->payload(
                restaurantId: 2,
                items: [
                    $this->item(6, 'Chickenjoy Meal', 'Bestsellers', 149, 1),
                ],
                address: ['label' => 'Tacloban City'],
                paymentMethod: 'gcash',
            ));

        $this->assertSame([
            'Distance_km' => 2.8,
            'Weather' => 'clear',
            'Traffic_Level' => 'low',
            'Time_of_Day' => 'afternoon',
            'Vehicle_Type' => 'motorcycle',
            'Preparation_Time_min' => 15,
            'Courier_Experience_yrs' => 3.5,
        ], $features);
    }

    public function test_chao_fan_order_builds_chao_fan_model_features(): void
    {
        Carbon::setTestNow('2026-05-18 21:05:00');

        $features = app(CheckoutPredictionFeatureBuilder::class)
            ->build($this->payload(
                restaurantSlug: 'chao-fan-house',
                items: [
                    $this->item(11, 'Pork Chao Fan', 'Bestsellers', 135, 2),
                    $this->item(13, 'Siomai', 'Dimsum', 90, 2),
                ],
                address: [
                    'label' => 'V&G Subdivision Extension',
                    'notes' => 'Near gate',
                ],
            ));

        $this->assertSame([
            'Distance_km' => 6.6,
            'Weather' => 'stormy',
            'Traffic_Level' => 'high',
            'Time_of_Day' => 'night',
            'Vehicle_Type' => 'motorcycle',
            'Preparation_Time_min' => 35,
            'Courier_Experience_yrs' => 1.0,
        ], $features);
    }

    public function test_larger_cart_increases_preparation_time(): void
    {
        Carbon::setTestNow('2026-05-18 10:00:00');

        $builder = app(CheckoutPredictionFeatureBuilder::class);

        $smallCart = $builder->build($this->payload(
            restaurantId: 2,
            items: [$this->item(6, 'Chickenjoy Meal', 'Bestsellers', 149, 2)],
        ));
        $largeCart = $builder->build($this->payload(
            restaurantId: 2,
            items: [$this->item(6, 'Chickenjoy Meal', 'Bestsellers', 149, 5)],
        ));

        $this->assertSame(15, $smallCart['Preparation_Time_min']);
        $this->assertSame(25, $largeCart['Preparation_Time_min']);
    }

    public function test_current_server_time_maps_to_time_of_day(): void
    {
        $builder = app(CheckoutPredictionFeatureBuilder::class);

        $expectations = [
            '2026-05-18 05:00:00' => 'morning',
            '2026-05-18 11:59:00' => 'morning',
            '2026-05-18 12:00:00' => 'afternoon',
            '2026-05-18 16:59:00' => 'afternoon',
            '2026-05-18 17:00:00' => 'evening',
            '2026-05-18 20:59:00' => 'evening',
            '2026-05-18 21:00:00' => 'night',
            '2026-05-18 04:59:00' => 'night',
        ];

        foreach ($expectations as $time => $expectedBucket) {
            Carbon::setTestNow($time);

            $features = $builder->build($this->payload());

            $this->assertSame($expectedBucket, $features['Time_of_Day'], $time);
        }
    }

    private function payload(
        ?int $restaurantId = 1,
        ?string $restaurantSlug = null,
        array $items = [],
        array $address = ['label' => 'Tacloban City'],
        string $paymentMethod = 'cod',
    ): array {
        $items = $items === []
            ? [$this->item(1, 'Pork Sinigang', 'Bestsellers', 185, 1)]
            : $items;

        return array_filter([
            'restaurant_id' => $restaurantId,
            'restaurant_slug' => $restaurantSlug,
            'items' => $items,
            'delivery_address' => $address,
            'payment_method' => $paymentMethod,
            'subtotal' => array_sum(array_map(
                fn (array $item): int => $item['unit_price'] * $item['quantity'],
                $items
            )),
            'total_quantity' => array_sum(array_column($items, 'quantity')),
        ], fn (mixed $value): bool => $value !== null);
    }

    private function item(
        int $id,
        string $name,
        string $category,
        int $unitPrice,
        int $quantity,
    ): array {
        return [
            'id' => $id,
            'name' => $name,
            'category' => $category,
            'quantity' => $quantity,
            'unit_price' => $unitPrice,
        ];
    }
}
