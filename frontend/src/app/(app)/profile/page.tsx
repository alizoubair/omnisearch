'use client'

import React from 'react';
import { useSession } from 'next-auth/react';
import { User, Mail, Calendar } from 'lucide-react';

export default function ProfilePage() {
  const { data: session } = useSession();

  return (
    <div className="max-w-4xl mx-auto p-6">
      <h1 className="text-3xl font-semibold mb-8">Profile</h1>

      <div className="bg-white dark:bg-neutral-900 rounded-lg border border-neutral-200 dark:border-neutral-800 p-6">
        <div className="flex items-center gap-6 mb-8">
          <div className="w-24 h-24 rounded-full bg-neutral-100 dark:bg-neutral-800 flex items-center justify-center">
            <User size={40} className="text-neutral-600 dark:text-neutral-400" />
          </div>
          <div>
            <h2 className="text-2xl font-semibold mb-1">{session?.user?.name || 'User'}</h2>
            <p className="text-neutral-600 dark:text-neutral-400">{session?.user?.email}</p>
          </div>
        </div>

        <div className="space-y-6">
          <div className="border-t border-neutral-200 dark:border-neutral-800 pt-6">
            <h3 className="text-lg font-semibold mb-4">Account Information</h3>
            
            <div className="space-y-4">
              <div className="flex items-center gap-3">
                <User size={20} className="text-neutral-500" />
                <div>
                  <p className="text-sm text-neutral-500 dark:text-neutral-400">Name</p>
                  <p className="font-medium">{session?.user?.name || 'Not set'}</p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <Mail size={20} className="text-neutral-500" />
                <div>
                  <p className="text-sm text-neutral-500 dark:text-neutral-400">Email</p>
                  <p className="font-medium">{session?.user?.email || 'Not set'}</p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <Calendar size={20} className="text-neutral-500" />
                <div>
                  <p className="text-sm text-neutral-500 dark:text-neutral-400">Member Since</p>
                  <p className="font-medium">{new Date().toLocaleDateString()}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
