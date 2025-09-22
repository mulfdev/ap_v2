import { useEffect } from "react";

interface ToastProps {
  message: string;
  type: "success" | "info" | "error";
  onClose: () => void;
}

export default function Toast({ message, type, onClose }: ToastProps) {
  useEffect(() => {
    const timer = setTimeout(() => {
      onClose();
    }, 4000); // Auto-dismiss after 4 seconds

    return () => clearTimeout(timer);
  }, [onClose]);

  const bgColor = {
    success: "bg-green-900 border-green-600 text-green-200",
    info: "bg-yellow-900 border-yellow-600 text-yellow-200",
    error: "bg-red-900 border-red-600 text-red-200",
  }[type];

  return (
    <div className={`fixed top-4 right-4 z-50 p-4 border rounded-md shadow-lg max-w-sm ${bgColor}`}>
      <div className="flex items-start justify-between">
        <p className="text-sm">{message}</p>
        <button
          onClick={onClose}
          className="ml-4 text-lg font-bold hover:opacity-75"
        >
          ×
        </button>
      </div>
    </div>
  );
}