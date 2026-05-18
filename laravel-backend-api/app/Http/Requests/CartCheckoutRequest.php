<?php

namespace App\Http\Requests;

use App\Services\FoodPulseLocalData;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;
use Illuminate\Validation\Rule;

class CartCheckoutRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'payment_method' => is_string($this->payment_method)
                ? strtolower($this->payment_method)
                : $this->payment_method,
        ]);
    }

    public function rules(): array
    {
        $foodPulseData = app(FoodPulseLocalData::class);

        return [
            'restaurant_id' => [
                'required',
                'integer',
                Rule::in($foodPulseData->restaurantIds()),
            ],
            'items' => ['required', 'array', 'min:1'],
            'items.*.menu_item_id' => [
                'required',
                'integer',
                Rule::in($foodPulseData->menuItemIds()),
            ],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:10'],
            'payment_method' => ['required', 'string', 'in:cod,cash,gcash,card'],
            'delivery_address' => ['required', 'array'],
            'delivery_address.label' => ['required', 'string', 'max:160'],
            'delivery_address.notes' => ['nullable', 'string', 'max:240'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $restaurantId = $this->integer('restaurant_id');
            $items = $this->input('items', []);

            if ($restaurantId === 0 || ! is_array($items)) {
                return;
            }

            $restaurantMenuItemIds = array_column(
                app(FoodPulseLocalData::class)->menuItems($restaurantId),
                'id'
            );

            foreach ($items as $index => $item) {
                if (! is_array($item) || ! isset($item['menu_item_id'])) {
                    continue;
                }

                if (! in_array((int) $item['menu_item_id'], $restaurantMenuItemIds, true)) {
                    $validator->errors()->add(
                        "items.$index.menu_item_id",
                        'The selected menu item is not available from this restaurant.'
                    );
                }
            }
        });
    }
}
