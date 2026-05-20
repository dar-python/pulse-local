<?php

namespace App\Services;

class CheckoutRiskAdvisoryResolver
{
    public function forPrediction(array $prediction, array $modelFeatures): array
    {
        if ($this->isLowRisk($prediction)) {
            return [
                'advisory_message' => 'Low risk. Conditions look favorable for this order.',
                'advisory_reasons' => [],
            ];
        }

        $reasons = array_slice($this->rankedDelayReasons($modelFeatures), 0, 2);

        if ($reasons === []) {
            return [
                'advisory_message' => 'No major delay reason detected for this order.',
                'advisory_reasons' => [],
            ];
        }

        return [
            'advisory_message' => 'Possible delay because of '.$this->reasonPhrase($reasons).'.',
            'advisory_reasons' => array_map(
                fn (array $reason): array => [
                    'code' => $reason['code'],
                    'label' => $reason['label'],
                ],
                $reasons
            ),
        ];
    }

    private function isLowRisk(array $prediction): bool
    {
        $level = strtolower((string) ($prediction['risk_level'] ?? ''));
        if ($level === 'low') {
            return true;
        }

        if (! isset($prediction['risk_score']) || ! is_numeric($prediction['risk_score'])) {
            return false;
        }

        $score = (float) $prediction['risk_score'];
        $normalizedScore = $score <= 1 ? $score : $score / 100;

        return $normalizedScore <= 0.39;
    }

    private function rankedDelayReasons(array $modelFeatures): array
    {
        $weather = strtolower((string) ($modelFeatures['Weather'] ?? ''));
        $traffic = strtolower((string) ($modelFeatures['Traffic_Level'] ?? ''));
        $timeOfDay = strtolower((string) ($modelFeatures['Time_of_Day'] ?? ''));
        $preparationTime = (int) ($modelFeatures['Preparation_Time_min'] ?? 0);
        $distance = (float) ($modelFeatures['Distance_km'] ?? 0);
        $courierExperience = (float) ($modelFeatures['Courier_Experience_yrs'] ?? 99);

        $reasons = [];

        if ($weather === 'stormy') {
            $reasons[] = $this->reason(
                10,
                'stormy_weather',
                'Bad weather may slow down delivery.',
                'bad weather'
            );
        }

        if ($traffic === 'high') {
            $reasons[] = $this->reason(
                20,
                'heavy_traffic',
                'Heavy traffic may delay the rider.',
                'heavy traffic'
            );
        }

        if ($preparationTime >= 30) {
            $reasons[] = $this->reason(
                30,
                'long_preparation',
                'This order may take longer to prepare.',
                'longer preparation time'
            );
        }

        if ($distance >= 5) {
            $reasons[] = $this->reason(
                40,
                'long_distance',
                'The delivery address is farther than usual.',
                'a farther delivery address'
            );
        }

        if ($courierExperience <= 1.5) {
            $reasons[] = $this->reason(
                50,
                'limited_rider_availability',
                'Limited rider availability may increase fulfillment risk.',
                'limited rider availability'
            );
        }

        if ($weather === 'rainy') {
            $reasons[] = $this->reason(
                60,
                'rainy_weather',
                'Bad weather may slow down delivery.',
                'bad weather'
            );
        }

        if (in_array($timeOfDay, ['evening', 'night'], true)) {
            $reasons[] = $this->reason(
                70,
                'peak_hour',
                'Peak-hour timing may affect delivery speed.',
                'peak-hour timing'
            );
        }

        if ($traffic === 'medium') {
            $reasons[] = $this->reason(
                80,
                'medium_traffic',
                'Moderate traffic may slightly affect delivery time.',
                'moderate traffic'
            );
        }

        usort($reasons, fn (array $left, array $right): int => $left['priority'] <=> $right['priority']);

        return $reasons;
    }

    private function reason(int $priority, string $code, string $label, string $summary): array
    {
        return [
            'priority' => $priority,
            'code' => $code,
            'label' => $label,
            'summary' => $summary,
        ];
    }

    private function reasonPhrase(array $reasons): string
    {
        $summaries = array_column($reasons, 'summary');

        if (count($summaries) === 1) {
            return $summaries[0];
        }

        return $summaries[0].' and '.$summaries[1];
    }
}
