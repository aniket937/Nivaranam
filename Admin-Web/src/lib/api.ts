import { supabase } from "./supabaseClient";

export type ComplaintRecord = {
  id: string;
  category: string;
  description: string;
  city: string;
  division: string;
  ward: string;
  status: string;
  priority: string;
  upvotes: number;
  user_id: number;
  submitted_at: string;
  thumbnail_url: string | null;
  latitude: number | null;
  longitude: number | null;
};

export type ContractorRecord = {
  id: string;
  name: string;
  type: string;
  rating: number;
  completed_jobs: number;
  active_jobs: number;
  status: string;
  phone: string | null;
  email: string | null;
  divisions?: string[];
};

export type AlertRecord = {
  id: string;
  type: string;
  message: string;
  division: string;
  related_id: string | null;
  created_at: string;
};

export async function fetchComplaints() {
  const { data, error } = await supabase.from("complaints").select("*").order("submitted_at", { ascending: false });
  if (error) throw error;
  return data as ComplaintRecord[];
}

export async function fetchContractors() {
  const { data: contractors, error } = await supabase.from("contractors").select("*").order("name");
  if (error) throw error;

  const { data: divisions } = await supabase.from("contractor_divisions").select("*");
  const divMap = new Map<string, string[]>();
  (divisions || []).forEach((row: any) => {
    const list = divMap.get(row.contractor_id) || [];
    list.push(row.division);
    divMap.set(row.contractor_id, list);
  });

  return (contractors || []).map((c) => ({
    ...c,
    divisions: divMap.get(c.id) || [],
  })) as ContractorRecord[];
}

export async function fetchAlerts() {
  const { data, error } = await supabase.from("alerts").select("*").order("created_at", { ascending: false });
  if (error) throw error;
  return data as AlertRecord[];
}

export async function fetchComplaint(id: string) {
  const { data, error } = await supabase.from("complaints").select("*").eq("id", id).single();
  if (error) throw error;
  return data as ComplaintRecord;
}

export async function fetchStats() {
  const complaints = await fetchComplaints();
  const alerts = await fetchAlerts();
  const contractors = await fetchContractors();

  const statusDistribution = complaints.reduce<Record<string, number>>((acc, c) => {
    acc[c.status] = (acc[c.status] || 0) + 1;
    return acc;
  }, {});

  const divisionComplaints = complaints.reduce<Record<string, number>>((acc, c) => {
    acc[c.division] = (acc[c.division] || 0) + 1;
    return acc;
  }, {});

  return {
    statusDistribution,
    divisionComplaints,
    totalComplaints: complaints.length,
    alertsCount: alerts.length,
    contractors,
  };
}

