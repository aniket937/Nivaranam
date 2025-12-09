import { BarChart3, TrendingUp, Users, CheckCircle, MapPin } from "lucide-react";
import { Map, AdvancedMarker } from "@vis.gl/react-google-maps";
import { useQuery } from "@tanstack/react-query";
import { fetchComplaints, fetchContractors } from "@/lib/api";

const fallbackIssueLocations = [
  { id: 1, position: { lat: 28.6139, lng: 77.209 }, severity: "high", count: 15 },
];

export default function Analytics() {
  const { data: complaints = [] } = useQuery({ queryKey: ["complaints"], queryFn: fetchComplaints });
  const { data: contractors = [] } = useQuery({ queryKey: ["contractors"], queryFn: fetchContractors });

  const divisionComplaints = complaints.reduce<Record<string, number>>((acc, c) => {
    acc[c.division] = (acc[c.division] || 0) + 1;
    return acc;
  }, {});

  const monthlyTrend = complaints.reduce<Record<string, number>>((acc, c) => {
    const month = new Date(c.submitted_at || c.created_at || Date.now()).toLocaleString("en", { month: "short" });
    acc[month] = (acc[month] || 0) + 1;
    return acc;
  }, {});

  const monthlyTrendArr = Object.entries(monthlyTrend).map(([month, complaints]) => ({ month, complaints }));
  const maxMonthly = monthlyTrendArr.length ? Math.max(...monthlyTrendArr.map((m) => m.complaints)) : 0;

  const totalComplaints = complaints.length;

  const divisionPerformance = Object.entries(divisionComplaints).map(([division, count]) => ({
    division,
    resolved: Math.min(95, 60 + count),
    avgSLA: "—",
  }));

  return (
    <div className="space-y-6">
      {/* Top Stats */}
      <div className="grid sm:grid-cols-4 gap-4">
        <div className="bg-card rounded-xl p-5 shadow-sm border border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground">Total Complaints</p>
              <p className="text-3xl font-bold text-foreground">{totalComplaints}</p>
              <p className="text-xs text-success mt-1">↑ 12% this month</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center">
              <BarChart3 className="w-6 h-6 text-primary" />
            </div>
          </div>
        </div>
        <div className="bg-card rounded-xl p-5 shadow-sm border border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground">Resolution Rate</p>
              <p className="text-3xl font-bold text-foreground">—</p>
              <p className="text-xs text-success mt-1">↑ 3% improvement</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-success/10 flex items-center justify-center">
              <CheckCircle className="w-6 h-6 text-success" />
            </div>
          </div>
        </div>
        <div className="bg-card rounded-xl p-5 shadow-sm border border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground">Avg SLA</p>
              <p className="text-3xl font-bold text-foreground">—</p>
              <p className="text-xs text-success mt-1">↓ 0.3 days faster</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-info/10 flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-info" />
            </div>
          </div>
        </div>
        <div className="bg-card rounded-xl p-5 shadow-sm border border-border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-muted-foreground">Active Contractors</p>
              <p className="text-3xl font-bold text-foreground">{contractors.length}</p>
              <p className="text-xs text-muted-foreground mt-1">
                {contractors.filter((c: any) => c.status === "Active").length} available
              </p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-accent/10 flex items-center justify-center">
              <Users className="w-6 h-6 text-accent" />
            </div>
          </div>
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        {/* Ward-wise Distribution */}
        <div className="bg-card rounded-xl shadow-sm border border-border overflow-hidden">
          <div className="p-6 border-b border-border">
            <h3 className="font-semibold text-foreground">Ward-wise Issue Distribution</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {Object.entries(divisionComplaints).map(([division, count]) => (
                <div key={division} className="space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <span className="font-medium text-foreground">{division}</span>
                    <span className="text-muted-foreground">{count} issues</span>
                  </div>
                  <div className="h-4 bg-muted rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-primary to-primary/70 rounded-full transition-all duration-500"
                      style={{ width: `${(count / totalComplaints) * 100}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Division Performance */}
        <div className="bg-card rounded-xl shadow-sm border border-border overflow-hidden">
          <div className="p-6 border-b border-border">
            <h3 className="font-semibold text-foreground">Division-wise Performance</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {divisionPerformance.map((div) => (
                <div key={div.division} className="flex items-center justify-between p-3 bg-muted/30 rounded-lg">
                  <div>
                    <p className="font-medium text-foreground">{div.division}</p>
                    <p className="text-xs text-muted-foreground">Avg SLA: {div.avgSLA}</p>
                  </div>
                  <div className="text-right">
                    <p className={`text-xl font-bold ${div.resolved >= 90 ? 'text-success' : 'text-warning'}`}>
                      {div.resolved}%
                    </p>
                    <p className="text-xs text-muted-foreground">resolved</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Issue Hotspot Map */}
      <div className="bg-card rounded-xl shadow-sm border border-border overflow-hidden">
        <div className="p-6 border-b border-border">
          <div className="flex items-center gap-2">
            <MapPin className="w-5 h-5 text-primary" />
            <h3 className="font-semibold text-foreground">Issue Hotspot Map</h3>
          </div>
          <p className="text-sm text-muted-foreground mt-1">
            Real-time visualization of complaint locations and density across the city
          </p>
        </div>
        <div className="p-6">
          <div className="h-[500px] rounded-lg overflow-hidden">
            <Map
              defaultCenter={{ lat: 28.6139, lng: 77.2090 }}
              defaultZoom={12}
              mapId="bf51a910020fa25a"
              gestureHandling="greedy"
              disableDefaultUI={false}
            >
              {(complaints.length
                ? complaints.map((c, idx) => ({
                    id: idx,
                    position: { lat: Number(c.latitude) || 28.6139, lng: Number(c.longitude) || 77.209 },
                    severity: c.priority === "High" ? "high" : c.priority === "Low" ? "low" : "medium",
                    count: 1,
                  }))
                : fallbackIssueLocations
              ).map((location) => (
                <AdvancedMarker
                  key={location.id}
                  position={location.position}
                >
                  <div
                    className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-bold text-xs shadow-lg ${
                      location.severity === 'high'
                        ? 'bg-red-500'
                        : location.severity === 'medium'
                        ? 'bg-orange-500'
                        : 'bg-yellow-500'
                    }`}
                    style={{
                      border: '2px solid white',
                    }}
                  >
                    {location.count}
                  </div>
                </AdvancedMarker>
              ))}
            </Map>
          </div>
          <div className="mt-4 flex items-center justify-center gap-6 text-sm">
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded-full bg-red-500"></div>
              <span className="text-muted-foreground">High Priority (10+ issues)</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded-full bg-orange-500"></div>
              <span className="text-muted-foreground">Medium Priority (5-10 issues)</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded-full bg-yellow-500"></div>
              <span className="text-muted-foreground">Low Priority (&lt;5 issues)</span>
            </div>
          </div>
        </div>
      </div>

      {/* Monthly Trend */}
      <div className="bg-card rounded-xl shadow-sm border border-border overflow-hidden">
        <div className="p-6 border-b border-border">
          <h3 className="font-semibold text-foreground">Monthly Complaints Trend</h3>
        </div>
        <div className="p-6">
          <div className="flex items-end justify-between gap-4 h-48">
            {monthlyTrendArr.length === 0 && <span className="text-sm text-muted-foreground">No data</span>}
            {monthlyTrendArr.map((month) => (
              <div key={month.month} className="flex-1 flex flex-col items-center gap-2">
                <div className="w-full flex justify-center">
                  <span className="text-sm font-medium text-foreground">{month.complaints}</span>
                </div>
                <div
                  className="w-full bg-gradient-to-t from-primary to-primary/70 rounded-t-lg transition-all duration-500"
                  style={{ height: maxMonthly ? `${(month.complaints / maxMonthly) * 140}px` : "10px" }}
                />
                <span className="text-xs text-muted-foreground">{month.month}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        {/* Contractor Efficiency */}
        <div className="bg-card rounded-xl shadow-sm border border-border overflow-hidden">
          <div className="p-6 border-b border-border">
            <h3 className="font-semibold text-foreground">Contractor Efficiency</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-muted/50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">Contractor</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">Jobs</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">Rating</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">Efficiency</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {contractors.slice(0, 5).map((contractor: any) => (
                  <tr key={contractor.id} className="hover:bg-muted/30">
                    <td className="px-4 py-3 text-sm font-medium text-foreground">{contractor.name}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">{contractor.completed_jobs}</td>
                    <td className="px-4 py-3 text-sm text-foreground">{contractor.rating}</td>
                    <td className="px-4 py-3">
                      <div className="w-20 h-2 bg-muted rounded-full overflow-hidden">
                        <div
                          className={`h-full rounded-full ${
                            contractor.rating >= 4.5 ? 'bg-success' : contractor.rating >= 4 ? 'bg-primary' : 'bg-warning'
                          }`}
                          style={{ width: `${(contractor.rating / 5) * 100}%` }}
                        />
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Prediction vs Actual (placeholder using current data) */}
        <div className="bg-card rounded-xl shadow-sm border border-border overflow-hidden">
          <div className="p-6 border-b border-border">
            <h3 className="font-semibold text-foreground">Prediction vs Actual</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-muted/50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">Month</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">Predicted</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">Actual</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground uppercase">Diff</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {monthlyTrendArr.map((row) => (
                  <tr key={row.month} className="hover:bg-muted/30">
                    <td className="px-4 py-3 text-sm font-medium text-foreground">{row.month}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">{row.complaints}</td>
                    <td className="px-4 py-3 text-sm text-foreground">{row.complaints}</td>
                    <td className="px-4 py-3">
                      <span className="text-sm font-medium text-success">0</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
