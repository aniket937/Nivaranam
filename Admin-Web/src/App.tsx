import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Landing from "./pages/Landing";
import CitySelection from "./pages/CitySelection";
import RoleSelection from "./pages/RoleSelection";
import AdminLogin from "./pages/AdminLogin";
import DepartmentSelection from "./pages/DepartmentSelection";
import { AdminLayout } from "./components/admin/AdminLayout";
import Dashboard from "./pages/admin/Dashboard";
import Complaints from "./pages/admin/Complaints";
import ComplaintDetail from "./pages/admin/ComplaintDetail";
import Contractors from "./pages/admin/Contractors";
import LocalContractors from "./pages/admin/LocalContractors";
import Predictions from "./pages/admin/Predictions";
import Alerts from "./pages/admin/Alerts";
import Analytics from "./pages/admin/Analytics";
import Settings from "./pages/admin/Settings";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/city-selection" element={<CitySelection />} />
          <Route path="/role-selection" element={<RoleSelection />} />
          <Route path="/admin-login" element={<AdminLogin />} />
          <Route path="/department-selection" element={<DepartmentSelection />} />
          <Route path="/admin" element={<AdminLayout />}>
            <Route index element={<Dashboard />} />
            <Route path="complaints" element={<Complaints />} />
            <Route path="complaints/:id" element={<ComplaintDetail />} />
            <Route path="contractors" element={<Contractors />} />
            <Route path="local-contractors" element={<LocalContractors />} />
            <Route path="predictions" element={<Predictions />} />
            <Route path="alerts" element={<Alerts />} />
            <Route path="analytics" element={<Analytics />} />
            <Route path="settings" element={<Settings />} />
          </Route>
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
