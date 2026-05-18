<?php

namespace App\Services;

class FoodPulseLocalData
{
    public const SOURCE = 'local-test-data';

    public function restaurants(): array
    {
        return [
            [
                'id' => 1,
                'name' => 'Tambayan Grill',
                'cuisine' => 'Filipino - Grills',
                'rating' => 4.8,
                'delivery_time' => '15-25 min',
                'minimum_order' => 99,
                'emoji' => $this->emoji('\ud83c\udf56'),
                'risk_score' => 28,
            ],
            [
                'id' => 2,
                'name' => 'Jollibee Express',
                'cuisine' => 'Fast Food',
                'rating' => 4.9,
                'delivery_time' => '10-20 min',
                'minimum_order' => 79,
                'emoji' => $this->emoji('\ud83c\udf57'),
                'risk_score' => 62,
            ],
            [
                'id' => 3,
                'name' => 'Chao Fan House',
                'cuisine' => 'Chinese - Meals',
                'rating' => 4.6,
                'delivery_time' => '20-35 min',
                'minimum_order' => 89,
                'emoji' => $this->emoji('\ud83c\udf5c'),
                'risk_score' => 81,
            ],
        ];
    }

    public function restaurantIds(): array
    {
        return array_column($this->restaurants(), 'id');
    }

    public function restaurant(int $restaurantId): ?array
    {
        foreach ($this->restaurants() as $restaurant) {
            if ($restaurant['id'] === $restaurantId) {
                return $restaurant;
            }
        }

        return null;
    }

    public function menuItemIds(): array
    {
        return array_column($this->menuItems(), 'id');
    }

    public function menuItems(?int $restaurantId = null): array
    {
        $items = [
            [
                'id' => 1,
                'restaurant_id' => 1,
                'name' => 'Pork Sinigang',
                'description' => 'Sour tamarind broth with tender pork ribs',
                'price' => 185,
                'emoji' => $this->emoji('\ud83c\udf72'),
                'category' => 'Bestsellers',
            ],
            [
                'id' => 2,
                'restaurant_id' => 1,
                'name' => 'Chicken Inasal',
                'description' => 'Charcoal-grilled chicken with garlic rice',
                'price' => 155,
                'emoji' => $this->emoji('\ud83c\udf57'),
                'category' => 'Bestsellers',
            ],
            [
                'id' => 3,
                'restaurant_id' => 1,
                'name' => 'Kare-Kare',
                'description' => 'Rich peanut stew with oxtail and veggies',
                'price' => 220,
                'emoji' => $this->emoji('\ud83e\udd58'),
                'category' => 'Specials',
            ],
            [
                'id' => 4,
                'restaurant_id' => 1,
                'name' => 'Halo-Halo',
                'description' => 'Shaved ice with mixed fruits and leche flan',
                'price' => 95,
                'emoji' => $this->emoji('\ud83c\udf67'),
                'category' => 'Desserts',
            ],
        ];

        if ($restaurantId === null) {
            return $items;
        }

        return array_values(array_filter(
            $items,
            fn (array $item): bool => $item['restaurant_id'] === $restaurantId
        ));
    }

    public function checkout(array $payload): array
    {
        $restaurant = $this->restaurant((int) $payload['restaurant_id']);
        $items = $this->checkoutItems($payload['items']);
        $subtotal = array_sum(array_column($items, 'line_total'));
        $deliveryFee = 49;
        $serviceCharge = 10;

        return [
            'order_number' => $this->orderNumber(),
            'status' => 'ready_for_confirmation',
            'restaurant' => $restaurant,
            'items' => $items,
            'payment_method' => $payload['payment_method'],
            'delivery_address' => $payload['delivery_address'],
            'subtotal' => $subtotal,
            'delivery_fee' => $deliveryFee,
            'service_charge' => $serviceCharge,
            'total' => $subtotal + $deliveryFee + $serviceCharge,
            'risk' => $this->checkoutRisk(),
        ];
    }

    public function orderConfirmation(string $orderNumber): ?array
    {
        if ($orderNumber !== $this->orderNumber()) {
            return null;
        }

        return [
            ...$this->checkout([
                'restaurant_id' => 1,
                'items' => [
                    ['menu_item_id' => 1, 'quantity' => 1],
                    ['menu_item_id' => 2, 'quantity' => 2],
                ],
                'payment_method' => 'cod',
                'delivery_address' => [
                    'label' => 'Marasbaras, Tacloban City',
                    'notes' => 'Zone 7, Leyte, Philippines',
                ],
            ]),
            'status' => 'confirmed',
            'estimated_arrival' => '30-45 min',
            'tracking_steps' => [
                ['label' => 'Order placed', 'done' => true],
                ['label' => 'Merchant preparing', 'done' => true],
                ['label' => 'Rider assigned', 'done' => false],
                ['label' => 'Out for delivery', 'done' => false],
            ],
        ];
    }

    private function checkoutItems(array $payloadItems): array
    {
        $menuItems = [];
        foreach ($this->menuItems() as $menuItem) {
            $menuItems[$menuItem['id']] = $menuItem;
        }

        return array_map(function (array $payloadItem) use ($menuItems): array {
            $menuItem = $menuItems[(int) $payloadItem['menu_item_id']];
            $quantity = (int) $payloadItem['quantity'];

            return [
                'menu_item_id' => $menuItem['id'],
                'name' => $menuItem['name'],
                'price' => $menuItem['price'],
                'quantity' => $quantity,
                'line_total' => $menuItem['price'] * $quantity,
            ];
        }, $payloadItems);
    }

    private function checkoutRisk(): array
    {
        return [
            'risk_score' => 68,
            'risk_level' => 'Medium',
            'recommendation' => 'Medium fulfillment risk. Keep ETA visible.',
        ];
    }

    private function orderNumber(): string
    {
        return 'FP-2024-9873';
    }

    private function emoji(string $unicodeEscape): string
    {
        return (string) json_decode('"'.$unicodeEscape.'"');
    }
}
