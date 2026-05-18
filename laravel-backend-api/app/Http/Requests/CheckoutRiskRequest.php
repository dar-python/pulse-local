<?php

namespace App\Http\Requests;

use App\Http\Requests\Concerns\ReturnsApiValidationErrors;
use Illuminate\Foundation\Http\FormRequest;

class CheckoutRiskRequest extends FormRequest
{
    use ReturnsApiValidationErrors;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'traffic_corridor_intensity' => is_string($this->traffic_corridor_intensity)
                ? strtolower($this->traffic_corridor_intensity)
                : $this->traffic_corridor_intensity,

            'weather_category' => is_string($this->weather_category)
                ? strtolower($this->weather_category)
                : $this->weather_category,

            'address_complexity' => is_string($this->address_complexity)
                ? strtolower($this->address_complexity)
                : $this->address_complexity,

            'payment_method' => is_string($this->payment_method)
                ? strtolower($this->payment_method)
                : $this->payment_method,
        ]);
    }

    public function rules(): array
    {
        return [
            'rider_to_order_ratio' => ['required', 'numeric', 'min:0'],
            'merchant_prep_time' => ['required', 'integer', 'min:1'],
            'traffic_corridor_intensity' => ['required', 'string', 'in:low,medium,high'],
            'weather_category' => ['required', 'string', 'in:clear,rainy,stormy'],
            'delivery_distance_km' => ['required', 'numeric', 'min:0'],
            'address_complexity' => ['required', 'string', 'in:low,medium,high'],
            'payment_method' => ['required', 'string', 'in:cod,cash,gcash,card'],
        ];
    }
}
