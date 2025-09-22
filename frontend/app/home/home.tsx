import { Link } from "react-router";
import type { Route } from "./+types/home";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Artist Program V2" },
    { name: "description", content: "Create and manage your NFT collections" },
  ];
}

export default function Home() {
  return (
    <div className="min-h-screen py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md mx-auto bg-gray-800 rounded-lg shadow-lg p-6">
        <h1 className="text-3xl font-bold text-white mb-2">
          Artist Program
        </h1>
        <p className="text-gray-300 mb-6">
          Share your art with the world. Create unique digital artworks with
          built-in monetization and community features.
        </p>
        <Link
          to="/create"
          className="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Create Your Artwork
        </Link>
      </div>
    </div>
  );
}
