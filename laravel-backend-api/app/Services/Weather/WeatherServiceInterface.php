<?php

namespace App\Services\Weather;

use App\Data\ResolvedWeatherData;

interface WeatherServiceInterface
{
    public function currentForCheckout(array $checkoutContext): ResolvedWeatherData;
}
