"use client";

import { useEffect, useState } from "react";
import * as api from "@/lib/api";
import { isoToDisplayDateString } from "@/lib/date";

type LicenceType = { id: number; name: string };
type Licence = {
  id: number;
  licence_type: number;
  licence_number: string;
  issue_date: string;
  expiry_date: string | null;
};

const inputClass =
  "w-full rounded-lg border border-brand-grey-border px-3 py-2 text-sm outline-none focus:border-brand-green focus:ring-1 focus:ring-brand-green";

export default function SeedLicencePage() {
  const [types, setTypes] = useState<LicenceType[]>([]);
  const [licencesByType, setLicencesByType] = useState<Record<number, Licence>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingTypeId, setEditingTypeId] = useState<number | null>(null);

  async function load() {
    setIsLoading(true);
    setError(null);
    try {
      const categories = await api.getLicenceCategories();
      const category = categories.find(
        (c: { name: string }) => c.name === "Seed"
      );
      if (!category) {
        setError("Seed category not found.");
        setIsLoading(false);
        return;
      }
      const [typesData, licences] = await Promise.all([
        api.getLicenceTypes(category.id),
        api.getMyLicencesByCategory(category.id),
      ]);
      const byType: Record<number, Licence> = {};
      for (const l of licences) byType[l.licence_type] = l;
      setTypes(typesData);
      setLicencesByType(byType);
    } catch {
      setError("Could not load licences. Check your connection.");
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    queueMicrotask(load);
  }, []);

  async function deleteLicence(licence: Licence, typeName: string) {
    if (
      !confirm(
        `This will permanently delete the ${typeName} licence. Continue?`
      )
    )
      return;
    try {
      await api.deleteLicence(licence.id);
      load();
    } catch {
      setError("Could not delete this licence. Please try again.");
    }
  }

  if (isLoading) return <p className="text-black/50">Loading...</p>;
  if (error) return <p className="text-red-600">{error}</p>;

  return (
    <div>
      <h1 className="text-2xl font-bold text-black">Seed Licence</h1>
      <div className="mt-6 space-y-4">
        {types.map((type) => {
          const licence = licencesByType[type.id];
          return (
            <div key={type.id} className="rounded-xl border border-brand-grey-border p-5">
              <div className="flex items-start justify-between">
                <h2 className="font-bold">{type.name}</h2>
                {licence && (
                  <button
                    onClick={() => deleteLicence(licence, type.name)}
                    className="text-sm text-red-600 hover:underline"
                  >
                    Delete
                  </button>
                )}
              </div>

              {editingTypeId === type.id ? (
                <SeedLicenceForm
                  licenceTypeId={type.id}
                  existingLicence={licence}
                  onSaved={() => {
                    setEditingTypeId(null);
                    load();
                  }}
                  onCancel={() => setEditingTypeId(null)}
                />
              ) : (
                <>
                  {!licence ? (
                    <p className="mt-2 text-sm text-black/50">Not added yet.</p>
                  ) : (
                    <div className="mt-2 space-y-1 text-sm">
                      <p>
                        <span className="text-black/50">Licence No: </span>
                        <span className="font-semibold">{licence.licence_number}</span>
                      </p>
                      <p>
                        <span className="text-black/50">Date of Issue: </span>
                        <span className="font-semibold">
                          {isoToDisplayDateString(licence.issue_date)}
                        </span>
                      </p>
                      <p>
                        <span className="text-black/50">Date of Expiry: </span>
                        <span className="font-semibold">
                          {licence.expiry_date
                            ? isoToDisplayDateString(licence.expiry_date)
                            : "-"}
                        </span>
                      </p>
                    </div>
                  )}
                  <button
                    onClick={() => setEditingTypeId(type.id)}
                    className="mt-3 rounded-lg bg-brand-green px-4 py-2 text-sm font-semibold text-white hover:brightness-95"
                  >
                    {licence ? "Update Licence" : "Add Licence"}
                  </button>
                </>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

function SeedLicenceForm({
  licenceTypeId,
  existingLicence,
  onSaved,
  onCancel,
}: {
  licenceTypeId: number;
  existingLicence?: Licence;
  onSaved: () => void;
  onCancel: () => void;
}) {
  const [licenceNumber, setLicenceNumber] = useState(
    existingLicence?.licence_number ?? ""
  );
  const [issueDate, setIssueDate] = useState(existingLicence?.issue_date ?? "");
  const [expiryDate, setExpiryDate] = useState(existingLicence?.expiry_date ?? "");
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!licenceNumber.trim())
      return setError("The Licence Number field is not filled, please do fill it.");
    if (!issueDate)
      return setError(
        "The Date of Issue of Licence field is not filled, please do fill it."
      );
    if (!expiryDate)
      return setError(
        "The Date of Expiry of Licence field is not filled, please do fill it."
      );

    setIsSaving(true);
    setError(null);
    try {
      if (existingLicence) {
        await api.updateLicence(existingLicence.id, {
          licence_type: licenceTypeId,
          licence_number: licenceNumber.trim(),
          issue_date: issueDate,
          expiry_date: expiryDate,
        });
      } else {
        const profile = await api.getMyDealerProfile();
        if (!profile) {
          setError("Could not find your dealer account. Please log in again.");
          return;
        }
        await api.createLicence({
          dealer: profile.id,
          licence_type: licenceTypeId,
          licence_number: licenceNumber.trim(),
          issue_date: issueDate,
          expiry_date: expiryDate,
        });
      }
      onSaved();
    } catch (err) {
      const data = err instanceof api.ApiError ? err.data : null;
      setError(
        data ? JSON.stringify(data) : "Failed to save licence. Please try again."
      );
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <form onSubmit={submit} className="mt-3 space-y-3 border-t border-brand-grey-border pt-3">
      <input
        className={inputClass}
        placeholder="Licence Number"
        value={licenceNumber}
        onChange={(e) => setLicenceNumber(e.target.value)}
      />
      <div>
        <label className="text-xs text-black/50">Date of Issue of Licence</label>
        <input
          type="date"
          className={inputClass}
          value={issueDate}
          onChange={(e) => setIssueDate(e.target.value)}
        />
      </div>
      <div>
        <label className="text-xs text-black/50">Date of Expiry of Licence</label>
        <input
          type="date"
          className={inputClass}
          value={expiryDate}
          onChange={(e) => setExpiryDate(e.target.value)}
        />
      </div>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <div className="flex gap-2">
        <button
          type="submit"
          disabled={isSaving}
          className="rounded-lg bg-brand-green px-4 py-2 text-sm font-semibold text-white hover:brightness-95 disabled:opacity-50"
        >
          {isSaving ? "Saving..." : "Save"}
        </button>
        <button
          type="button"
          onClick={onCancel}
          className="rounded-lg border border-brand-grey-border px-4 py-2 text-sm font-semibold hover:bg-black/5"
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
