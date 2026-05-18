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
                'slug' => 'tambayan-grill',
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
                'slug' => 'jollibee-express',
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
                'slug' => 'chao-fan-house',
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
                'name' => 'Lechon Kawali',
                'description' => 'Crispy pork belly with liver sauce',
                'price' => 210,
                'emoji' => $this->emoji('\ud83e\udd69'),
                'category' => 'Mains',
            ],
            [
                'id' => 4,
                'restaurant_id' => 1,
                'name' => 'Pancit Canton',
                'description' => 'Stir-fried noodles with vegetables and pork',
                'price' => 145,
                'emoji' => $this->emoji('\ud83c\udf5c'),
                'category' => 'Mains',
            ],
            [
                'id' => 5,
                'restaurant_id' => 1,
                'name' => 'Halo-Halo',
                'description' => 'Shaved ice with mixed fruits and leche flan',
                'price' => 95,
                'emoji' => $this->emoji('\ud83c\udf67'),
                'category' => 'Desserts',
            ],
            [
                'id' => 6,
                'restaurant_id' => 2,
                'name' => 'Chickenjoy Meal',
                'description' => 'Crispy fried chicken with rice and gravy',
                'price' => 149,
                'emoji' => $this->emoji('\ud83c\udf57'),
                'category' => 'Bestsellers',
            ],
            [
                'id' => 7,
                'restaurant_id' => 2,
                'name' => 'Jolly Spaghetti',
                'description' => 'Sweet-style spaghetti with hotdog slices',
                'price' => 85,
                'emoji' => $this->emoji('\ud83c\udf5d'),
                'category' => 'Bestsellers',
            ],
            [
                'id' => 8,
                'restaurant_id' => 2,
                'name' => 'Yumburger',
                'description' => 'Classic burger with signature dressing',
                'price' => 55,
                'emoji' => $this->emoji('\ud83c\udf54'),
                'category' => 'Sandwiches',
            ],
            [
                'id' => 9,
                'restaurant_id' => 2,
                'name' => 'Burger Steak',
                'description' => 'Burger patties with mushroom gravy and rice',
                'price' => 99,
                'emoji' => $this->emoji('\ud83c\udf5b'),
                'category' => 'Rice Meals',
            ],
            [
                'id' => 10,
                'restaurant_id' => 2,
                'name' => 'Peach Mango Pie',
                'description' => 'Crispy pocket pie with peach mango filling',
                'price' => 49,
                'emoji' => $this->emoji('\ud83e\udd67'),
                'category' => 'Desserts',
            ],
            [
                'id' => 11,
                'restaurant_id' => 3,
                'name' => 'Pork Chao Fan',
                'description' => 'Wok-fried rice with pork and vegetables',
                'price' => 135,
                'emoji' => $this->emoji('\ud83c\udf5a'),
                'category' => 'Bestsellers',
            ],
            [
                'id' => 12,
                'restaurant_id' => 3,
                'name' => 'Beef Chao Fan',
                'description' => 'Wok-fried rice with savory beef strips',
                'price' => 155,
                'emoji' => $this->emoji('\ud83c\udf5a'),
                'category' => 'Bestsellers',
            ],
            [
                'id' => 13,
                'restaurant_id' => 3,
                'name' => 'Siomai',
                'description' => 'Steamed pork dumplings with chili garlic',
                'price' => 90,
                'emoji' => $this->emoji('\ud83e\udd5f'),
                'category' => 'Dimsum',
            ],
            [
                'id' => 14,
                'restaurant_id' => 3,
                'name' => 'Wonton Noodles',
                'description' => 'Noodle soup with wontons and spring onions',
                'price' => 120,
                'emoji' => $this->emoji('\ud83c\udf5c'),
                'category' => 'Noodles',
            ],
            [
                'id' => 15,
                'restaurant_id' => 3,
                'name' => 'Buchi',
                'description' => 'Sesame rice balls with sweet filling',
                'price' => 65,
                'emoji' => $this->emoji('\ud83c\udf61'),
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
