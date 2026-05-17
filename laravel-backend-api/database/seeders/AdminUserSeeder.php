<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    /**
     * @Dashboard: Seeds repeatable local admin accounts without storing plain text passwords.
     */
    public function run(): void
    {
        $accounts = [
            [
                'username' => 'admin',
                'name' => 'Admin User',
                'email' => 'admin@pulselocal.local',
                'password' => 'admin123',
                'role' => 'admin',
            ],
            [
                'username' => 'superadmin',
                'name' => 'Super Admin',
                'email' => 'superadmin@pulselocal.local',
                'password' => 'superadmin123',
                'role' => 'super_admin',
            ],
        ];

        foreach ($accounts as $account) {
            User::updateOrCreate(
                ['username' => $account['username']],
                [
                    'name' => $account['name'],
                    'email' => $account['email'],
                    'password' => Hash::make($account['password']),
                    'role' => $account['role'],
                ]
            );
        }
    }
}
