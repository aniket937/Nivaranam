import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { AdminSidebar } from './AdminSidebar';
import { AdminHeader } from './AdminHeader';
import { cn } from '@/lib/utils';

interface AdminLayoutProps {
  title?: string;
}

export function AdminLayout({ title = 'Dashboard' }: AdminLayoutProps) {
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);

  return (
    <div className="min-h-screen bg-background">
      <AdminSidebar 
        isCollapsed={isSidebarCollapsed} 
        onToggle={() => setIsSidebarCollapsed(!isSidebarCollapsed)} 
      />
      
      <div className={cn(
        'transition-all duration-300',
        isSidebarCollapsed ? 'ml-16' : 'ml-64'
      )}>
        <AdminHeader title={title} />
        <main className="p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
