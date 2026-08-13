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
};
type Entry = {
  id: number;
  company_name: string;
  valid_upto: string;
};

const inputClass =
  "w-full rounded-lg border border-brand-grey-border px-3 py-2 text-sm outline-none focus:border-brand-green focus:ring-1 focus:ring-brand-green";

export default function PesticideLicencePage() {
  const [types, setTypes] = useState<LicenceType[]>([]);
  const [licencesByType, setLicencesByType] = useState<Record<number, Licence>>({});
  const [entriesByType, setEntriesByType] = useState<Record<number, Entry[]>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingTypeId, setEditingTypeId] = useState<number | null>(null);

  async function load() {
    setIsLoading(true);
    setError(null);
    try {
      const categories = await api.getLicenceCategories();
      const category = categories.find(
        (c: { name: string }) => c.name === "Pesticide"
      );
      if (!category) {
        setError("Pesticide category not found.");
        setIsLoading(false);
        return;
      }
      const [typesData, licences] = await Promise.all([
        api.getLicenceTypes(category.id),
        api.getMyLicencesByCategory(category.id),
      ]);
      const byType: Record<number, Licence> = {};
      const entriesMap: Record<number, Entry[]> = {};
      for (const l of licences) {
        byType[l.licence_type] = l;
        entriesMap[l.licence_type] = await api.getLicenceEntries(l.id);
      }
      setTypes(typesData);
      setLicencesByType(byType);
      setEntriesByType(entriesMap);
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
        `This will permanently delete the ${typeName} licence and all its entries. Continue?`
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
      <h1 className="text-2xl font-bold text-black">Pesticide Licence</h1>
      <div className="mt-6 space-y-4">
        {types.map((type) => {
          const licence = licencesByType[type.id];
          const entries = entriesByType[type.id] ?? [];
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
                <PesticideLicenceForm
                  licenceTypeId={type.id}
                  existingLicence={licence}
                  existingEntries={entries}
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
                      <p className="mt-2 font-semibold">PC Entries</p>
                      {entries.length === 0 ? (
                        <p className="text-black/50">No entries added yet.</p>
                      ) : (
                        entries.map((e) => (
                          <div key={e.id} className="border-t border-brand-grey-border pt-1">
                            <p>{e.company_name}</p>
                            <p className="text-xs text-black/50">
                              PC Validity Date: {isoToDisplayDateString(e.valid_upto)}
                            </p>
                          </div>
                        ))
                      )}
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

type EntryDraft = { existingId?: number; companyName: string; validUpto: string };

function PesticideLicenceForm({
  licenceTypeId,
  existingLicence,
  existingEntries,
  onSaved,
  onCancel,
}: {
  licenceTypeId: number;
  existingLicence?: Licence;
  existingEntries: Entry[];
  onSaved: () => void;
  onCancel: () => void;
}) {
  const [licenceNumber, setLicenceNumber] = useState(
    existingLicence?.licence_number ?? ""
  );
  const [issueDate, setIssueDate] = useState(existingLicence?.issue_date ?? "");
  const [entries, setEntries] = useState<EntryDraft[]>(
    existingEntries.length > 0
      ? existingEntries.map((e) => ({
          existingId: e.id,
          companyName: e.company_name,
          validUpto: e.valid_upto,
        }))
      : [{ companyName: "", validUpto: "" }]
  );
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function updateEntry(index: number, patch: Partial<EntryDraft>) {
    setEntries((prev) => prev.map((e, i) => (i === index ? { ...e, ...patch } : e)));
  }

  function addRow() {
    setEntries((prev) => [...prev, { companyName: "", validUpto: "" }]);
  }

  async function removeRow(index: number) {
    if (entries.length === 1) return;
    const entry = entries[index];
    if (entry.existingId) {
      if (!confirm("This will permanently delete this PC entry. Continue?")) return;
      try {
        await api.deleteLicenceEntry(entry.existingId);
      } catch {
        setError("Could not remove this entry. Please try again.");
        return;
      }
    }
    setEntries((prev) => prev.filter((_, i) => i !== index));
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!licenceNumber.trim())
      return setError("The Licence Number field is not filled, please do fill it.");
    if (!issueDate)
      return setError(
        "The Date of Issue of Licence field is not filled, please do fill it."
      );
    for (let i = 0; i < entries.length; i++) {
      if (!entries[i].companyName.trim())
        return setError(`PC Entry ${i + 1}: Name of Company is not filled, please do fill it.`);
      if (!entries[i].validUpto)
        return setError(`PC Entry ${i + 1}: PC Validity Date is not filled, please do fill it.`);
    }

    setIsSaving(true);
    setError(null);
    try {
      let licenceId = existingLicence?.id;
      if (licenceId) {
        await api.updateLicence(licenceId, {
          licence_type: licenceTypeId,
          licence_number: licenceNumber.trim(),
          issue_date: issueDate,
        });
      } else {
        const profile = await api.getMyDealerProfile();
        if (!profile) {
          setError("Could not find your dealer account. Please log in again.");
          return;
        }
        const created = await api.createLicence({
          dealer: profile.id,
          licence_type: licenceTypeId,
          licence_number: licenceNumber.trim(),
          issue_date: issueDate,
        });
        licenceId = created.id;
      }

      for (const entry of entries) {
        if (entry.existingId) {
          await api.updateLicenceEntry(entry.existingId, {
            company_name: entry.companyName.trim(),
            valid_upto: entry.validUpto,
          });
        } else {
          await api.createLicenceEntry({
            licence: licenceId!,
            company_name: entry.companyName.trim(),
            valid_upto: entry.validUpto,
          });
        }
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

      <p className="text-sm font-semibold">PC Entries</p>
      {entries.map((entry, index) => (
        <div key={index} className="space-y-2 rounded-lg border border-brand-grey-border p-3">
          <div className="flex items-center justify-between">
            <p className="text-sm font-semibold">PC Entry {index + 1}</p>
            {entries.length > 1 && (
              <button
                type="button"
                onClick={() => removeRow(index)}
                className="text-xs text-red-600 hover:underline"
              >
                Remove
              </button>
            )}
          </div>
          <input
            className={inputClass}
            placeholder="Name of Company"
            value={entry.companyName}
            onChange={(e) => updateEntry(index, { companyName: e.target.value })}
          />
          <div>
            <label className="text-xs text-black/50">PC Validity Date</label>
            <input
              type="date"
              className={inputClass}
              value={entry.validUpto}
              onChange={(e) => updateEntry(index, { validUpto: e.target.value })}
            />
          </div>
        </div>
      ))}
      <button
        type="button"
        onClick={addRow}
        className="rounded-lg border border-brand-grey-border px-4 py-2 text-sm font-semibold hover:bg-black/5"
      >
        + Add Another PC Entry
      </button>

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
