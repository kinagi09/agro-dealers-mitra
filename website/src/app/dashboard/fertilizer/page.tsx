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
type Entry = {
  id: number;
  source_type: string | null;
  company_name: string;
  fertilizer_type: number[];
  valid_upto: string;
};
type FertilizerType = { id: number; name: string };

const inputClass =
  "w-full rounded-lg border border-brand-grey-border px-3 py-2 text-sm outline-none focus:border-brand-green focus:ring-1 focus:ring-brand-green";

// Display order: Retailer, District Wholesale Dealer, State Wholesale
// Dealer - matches the mobile app's explicit ordering, not the API's
// default alphabetical order.
const TYPE_ORDER_KEYWORDS = ["retail", "district", "state"];
function typeSortOrder(name: string) {
  const lower = name.toLowerCase();
  const index = TYPE_ORDER_KEYWORDS.findIndex((k) => lower.includes(k));
  return index === -1 ? TYPE_ORDER_KEYWORDS.length : index;
}

function entryLabel(entry: Entry) {
  return entry.source_type
    ? `${entry.source_type} (${entry.company_name})`
    : entry.company_name;
}

export default function FertilizerLicencePage() {
  const [types, setTypes] = useState<LicenceType[]>([]);
  const [licencesByType, setLicencesByType] = useState<Record<number, Licence>>({});
  const [entriesByType, setEntriesByType] = useState<Record<number, Entry[]>>({});
  const [fertilizerTypes, setFertilizerTypes] = useState<FertilizerType[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editingTypeId, setEditingTypeId] = useState<number | null>(null);

  async function load() {
    setIsLoading(true);
    setError(null);
    try {
      const categories = await api.getLicenceCategories();
      const category = categories.find(
        (c: { name: string }) => c.name === "Fertilizer"
      );
      if (!category) {
        setError("Fertilizer category not found.");
        setIsLoading(false);
        return;
      }
      const [typesData, licences, fertTypes] = await Promise.all([
        api.getLicenceTypes(category.id),
        api.getMyLicencesByCategory(category.id),
        api.getFertilizerTypes(),
      ]);
      typesData.sort(
        (a: LicenceType, b: LicenceType) =>
          typeSortOrder(a.name) - typeSortOrder(b.name)
      );
      const byType: Record<number, Licence> = {};
      const entriesMap: Record<number, Entry[]> = {};
      for (const l of licences) {
        byType[l.licence_type] = l;
        entriesMap[l.licence_type] = await api.getLicenceEntries(l.id);
      }
      setTypes(typesData);
      setLicencesByType(byType);
      setEntriesByType(entriesMap);
      setFertilizerTypes(fertTypes);
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
      <h1 className="text-2xl font-bold text-black">Fertilizer Licence</h1>
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
                <FertilizerLicenceForm
                  licenceTypeId={type.id}
                  existingLicence={licence}
                  existingEntries={entries}
                  fertilizerTypes={fertilizerTypes}
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
                      <p className="mt-2 font-semibold">O-form Entries</p>
                      {entries.length === 0 ? (
                        <p className="text-black/50">No entries added yet.</p>
                      ) : (
                        entries.map((e) => (
                          <div key={e.id} className="border-t border-brand-grey-border pt-1">
                            <p>{entryLabel(e)}</p>
                            <p className="text-xs text-black/50">
                              Valid Upto: {isoToDisplayDateString(e.valid_upto)}
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

type EntryDraft = {
  existingId?: number;
  sourceType: string;
  companyName: string;
  fertilizerTypeIds: number[];
  validUpto: string;
};

function FertilizerLicenceForm({
  licenceTypeId,
  existingLicence,
  existingEntries,
  fertilizerTypes,
  onSaved,
  onCancel,
}: {
  licenceTypeId: number;
  existingLicence?: Licence;
  existingEntries: Entry[];
  fertilizerTypes: FertilizerType[];
  onSaved: () => void;
  onCancel: () => void;
}) {
  const [licenceNumber, setLicenceNumber] = useState(
    existingLicence?.licence_number ?? ""
  );
  const [issueDate, setIssueDate] = useState(existingLicence?.issue_date ?? "");
  const [expiryDate, setExpiryDate] = useState(existingLicence?.expiry_date ?? "");
  const [entries, setEntries] = useState<EntryDraft[]>(
    existingEntries.length > 0
      ? existingEntries.map((e) => ({
          existingId: e.id,
          sourceType: e.source_type ?? "",
          companyName: e.company_name,
          fertilizerTypeIds: e.fertilizer_type,
          validUpto: e.valid_upto,
        }))
      : [{ sourceType: "", companyName: "", fertilizerTypeIds: [], validUpto: "" }]
  );
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function updateEntry(index: number, patch: Partial<EntryDraft>) {
    setEntries((prev) => prev.map((e, i) => (i === index ? { ...e, ...patch } : e)));
  }

  function toggleFertilizerType(index: number, id: number) {
    setEntries((prev) =>
      prev.map((e, i) => {
        if (i !== index) return e;
        const has = e.fertilizerTypeIds.includes(id);
        return {
          ...e,
          fertilizerTypeIds: has
            ? e.fertilizerTypeIds.filter((x) => x !== id)
            : [...e.fertilizerTypeIds, id],
        };
      })
    );
  }

  function addRow() {
    setEntries((prev) => [
      ...prev,
      { sourceType: "", companyName: "", fertilizerTypeIds: [], validUpto: "" },
    ]);
  }

  async function removeRow(index: number) {
    if (entries.length === 1) return;
    const entry = entries[index];
    if (entry.existingId) {
      if (!confirm("This will permanently delete this O-form entry. Continue?")) return;
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
    if (!expiryDate)
      return setError(
        "The Date of Expiry of Licence field is not filled, please do fill it."
      );
    for (let i = 0; i < entries.length; i++) {
      if (!entries[i].companyName.trim())
        return setError(
          `O-form Entry ${i + 1}: Source Company Name is not filled, please do fill it.`
        );
      if (entries[i].fertilizerTypeIds.length === 0)
        return setError(
          `O-form Entry ${i + 1}: At least one Type of Fertilizer must be selected.`
        );
      if (!entries[i].validUpto)
        return setError(
          `O-form Entry ${i + 1}: Valid Upto date is not filled, please do fill it.`
        );
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
          expiry_date: expiryDate,
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
          expiry_date: expiryDate,
        });
        licenceId = created.id;
      }

      for (const entry of entries) {
        if (entry.existingId) {
          await api.updateLicenceEntry(entry.existingId, {
            source_type: entry.sourceType.trim(),
            company_name: entry.companyName.trim(),
            fertilizer_type: entry.fertilizerTypeIds,
            valid_upto: entry.validUpto,
          });
        } else {
          await api.createLicenceEntry({
            licence: licenceId!,
            source_type: entry.sourceType.trim(),
            company_name: entry.companyName.trim(),
            fertilizer_type: entry.fertilizerTypeIds,
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
      <div>
        <label className="text-xs text-black/50">Date of Expiry of Licence</label>
        <input
          type="date"
          className={inputClass}
          value={expiryDate}
          onChange={(e) => setExpiryDate(e.target.value)}
        />
      </div>

      <p className="text-sm font-semibold">O-form Entries</p>
      {entries.map((entry, index) => (
        <div key={index} className="space-y-2 rounded-lg border border-brand-grey-border p-3">
          <div className="flex items-center justify-between">
            <p className="text-sm font-semibold">O-form Entry {index + 1}</p>
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
            placeholder="Source Type"
            value={entry.sourceType}
            onChange={(e) => updateEntry(index, { sourceType: e.target.value })}
          />
          <input
            className={inputClass}
            placeholder="Source Company Name"
            value={entry.companyName}
            onChange={(e) => updateEntry(index, { companyName: e.target.value })}
          />
          <div>
            <p className="text-xs text-black/50">Type(s) of Fertilizer</p>
            <div className="mt-1 flex flex-wrap gap-2">
              {fertilizerTypes.map((ft) => (
                <label
                  key={ft.id}
                  className={`cursor-pointer rounded-full border px-3 py-1 text-xs ${
                    entry.fertilizerTypeIds.includes(ft.id)
                      ? "border-brand-green bg-brand-green/10 text-brand-green"
                      : "border-brand-grey-border text-black/70"
                  }`}
                >
                  <input
                    type="checkbox"
                    className="hidden"
                    checked={entry.fertilizerTypeIds.includes(ft.id)}
                    onChange={() => toggleFertilizerType(index, ft.id)}
                  />
                  {ft.name}
                </label>
              ))}
            </div>
          </div>
          <div>
            <label className="text-xs text-black/50">Valid Upto</label>
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
        + Add Another O-form Entry
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
