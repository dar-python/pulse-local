<?php

namespace App\Services;

class AdminDashboardData
{
    /**
     * @Dashboard: Keeps the converted dashboard static until real admin tables are introduced.
     */
    public function toArray(): array
    {
        return [
            'metrics' => [
                ['label' => 'Total Users', 'value' => '28,940', 'note' => '+8.4% this month', 'tone' => ''],
                ['label' => 'Active Partners', 'value' => '412', 'note' => '386 approved', 'tone' => 'healthy'],
                ['label' => 'Orders Today', 'value' => '1,284', 'note' => '91% on track', 'tone' => ''],
                ['label' => 'High-Risk Orders', 'value' => '76', 'note' => 'Needs review', 'tone' => 'urgent'],
                ['label' => 'Open Disputes', 'value' => '23', 'note' => '7 escalated', 'tone' => 'urgent'],
                ['label' => 'Est. Revenue', 'value' => '$48.6K', 'note' => 'Today estimate', 'tone' => 'primary'],
            ],
            'chartBars' => [
                ['day' => 'Mon', 'height' => 42, 'type' => 'low'],
                ['day' => 'Tue', 'height' => 56, 'type' => 'mid'],
                ['day' => 'Wed', 'height' => 48, 'type' => 'low'],
                ['day' => 'Thu', 'height' => 69, 'type' => 'high'],
                ['day' => 'Fri', 'height' => 58, 'type' => 'mid'],
                ['day' => 'Sat', 'height' => 78, 'type' => 'high'],
                ['day' => 'Sun', 'height' => 72, 'type' => 'high'],
            ],
            'recentHighRiskOrders' => [
                ['id' => '#PL-88421', 'customer' => 'Mia Collins', 'merchant' => 'Harbor Noodle Bar', 'score' => '0.92', 'risk' => 'high', 'status' => 'open'],
                ['id' => '#PL-88409', 'customer' => 'Andre Hill', 'merchant' => 'Green Bowl Market', 'score' => '0.87', 'risk' => 'high', 'status' => 'monitoring'],
                ['id' => '#PL-88396', 'customer' => 'Jenna Stone', 'merchant' => 'Northside Bakery', 'score' => '0.81', 'risk' => 'high', 'status' => 'resolved'],
                ['id' => '#PL-88372', 'customer' => 'Leo Santos', 'merchant' => 'Cedar Grill', 'score' => '0.78', 'risk' => 'medium', 'status' => 'open'],
            ],
            'partnerPerformance' => [
                ['name' => 'Harbor Noodle Bar', 'prep' => '19 min', 'success' => '96.2%', 'risk' => 12, 'status' => 'approved'],
                ['name' => 'Cedar Grill', 'prep' => '26 min', 'success' => '88.9%', 'risk' => 18, 'status' => 'medium'],
                ['name' => 'Northside Bakery', 'prep' => '15 min', 'success' => '98.4%', 'risk' => 4, 'status' => 'approved'],
                ['name' => 'Metro Express Bites', 'prep' => '34 min', 'success' => '72.1%', 'risk' => 31, 'status' => 'suspended'],
            ],
            'disputeQueue' => [
                ['id' => 'DSP-1048', 'user' => 'Mia Collins', 'order' => '#PL-88421', 'reason' => 'Late delivery', 'status' => 'open'],
                ['id' => 'DSP-1045', 'user' => 'Andre Hill', 'order' => '#PL-88409', 'reason' => 'Missing item', 'status' => 'monitoring'],
                ['id' => 'DSP-1038', 'user' => 'Tara Miles', 'order' => '#PL-88251', 'reason' => 'Refund request', 'status' => 'resolved'],
            ],
            'operationalSnapshot' => [
                ['label' => 'Pending', 'value' => '184', 'note' => 'Awaiting partner', 'tone' => 'warn'],
                ['label' => 'Completed', 'value' => '1,046', 'note' => 'Closed today', 'tone' => 'pos'],
                ['label' => 'Delayed', 'value' => '38', 'note' => 'Past handoff', 'tone' => 'danger'],
                ['label' => 'Failed', 'value' => '14', 'note' => 'Unfulfilled', 'tone' => 'danger'],
                ['label' => 'Rider ratio', 'value' => '1:7.4', 'note' => 'Active zones', 'tone' => 'neutral'],
                ['label' => 'Avg distance', 'value' => '3.8 mi', 'note' => 'Estimated', 'tone' => 'neutral'],
            ],
            'financialSummary' => [
                ['label' => 'Gross Merch. Value', 'value' => '$324.8K', 'note' => 'Total order value', 'tone' => 'neutral'],
                ['label' => 'Platform Commission', 'value' => '$52.1K', 'note' => 'Before refunds', 'tone' => 'pos'],
                ['label' => 'Refund Amount', 'value' => '$3.5K', 'note' => 'Open + processed', 'tone' => 'danger'],
                ['label' => 'Net Revenue Est.', 'value' => '$48.6K', 'note' => 'Commission less refunds', 'tone' => 'warn'],
            ],
        ];
    }
}
