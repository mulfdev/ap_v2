import { useState, useEffect } from "react";
import { Link } from "react-router";
import {
  useWriteContract,
  useAccount,
  useWaitForTransactionReceipt,
  useWatchContractEvent,
} from "wagmi";
import { ConnectKitButton } from "connectkit";
import { ap1155Abi } from "../abi/ap1155";
import { apFactory } from "../abi/apfactory";
import Toast from "../Toast";

// TODO: Replace with actual deployed factory address
const FACTORY_ADDRESS = "0x0000000000000000000000000000000000000000";

export default function Create() {
  const [currentStep, setCurrentStep] = useState(1);
  const [deployedContract, setDeployedContract] = useState<string | null>(null);

  // Collection metadata
  const [collectionName, setCollectionName] = useState("");
  const [collectionSymbol, setCollectionSymbol] = useState("");
  const [collectionDescription, setCollectionDescription] = useState("");
  const [collectionImage, setCollectionImage] = useState("");
  const [collectionExternalLink, setCollectionExternalLink] = useState("");

  // Token metadata
  const [tokenId, setTokenId] = useState("");
  const [tokenName, setTokenName] = useState("");
  const [tokenDescription, setTokenDescription] = useState("");
  const [tokenImage, setTokenImage] = useState("");
  const [expiration, setExpiration] = useState("");

  const { address, isConnected } = useAccount();
  const { writeContract: writeFactory, data: factoryHash, isPending: factoryPending, error: factoryError } = useWriteContract();
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: factoryConfirming, isSuccess: factorySuccess } = useWaitForTransactionReceipt({
    hash: factoryHash,
  });
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  useWatchContractEvent({
    address: FACTORY_ADDRESS,
    abi: apFactory,
    eventName: 'CollectionCreated',
    onLogs: (logs) => {
      const newCollection = logs[0].args.newCollection as string;
      setDeployedContract(newCollection);
    },
  });

  useEffect(() => {
    if (deployedContract) {
      setCurrentStep(2);
    }
  }, [deployedContract]);

  const [toast, setToast] = useState<{
    message: string;
    type: "success" | "info" | "error";
    visible: boolean;
  } | null>(null);

  const nextStep = () => {
    if (currentStep === 1) {
      // Validate collection fields
      if (
        !collectionName ||
        !collectionSymbol ||
        !collectionDescription ||
        !collectionImage
      ) {
        setToast({
          message: "Please fill in all collection information",
          type: "error",
          visible: true,
        });
        return;
      }

      // Create collection metadata JSON
      const collectionMetadata = {
        name: collectionName,
        symbol: collectionSymbol,
        description: collectionDescription,
        image: collectionImage,
        external_link: collectionExternalLink,
      };

      // Base64 encode the JSON
      const collectionURI = `data:application/json;base64,${btoa(JSON.stringify(collectionMetadata))}`;

      writeFactory({
        address: FACTORY_ADDRESS,
        abi: apFactory,
        functionName: "deployNew",
        args: [
          collectionURI,
          0n, // creatorFee
          0n, // referralFee
          collectionName,
          collectionSymbol,
          collectionDescription,
          collectionImage,
          collectionExternalLink,
        ],
      });
    } else {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    setCurrentStep(currentStep - 1);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    e.preventDefault();

    if (!isConnected) {
      setToast({
        message: "Please connect your wallet first",
        type: "error",
        visible: true,
      });
      return;
    }

    if (!deployedContract) {
      setToast({
        message: "Collection not deployed yet",
        type: "error",
        visible: true,
      });
      return;
    }

    // Validate token fields
    if (!tokenId || !tokenName || !tokenDescription || !tokenImage) {
      setToast({
        message: "Please fill in all artwork information",
        type: "error",
        visible: true,
      });
      return;
    }

    // Create token metadata JSON
    const tokenMetadata = {
      name: tokenName,
      description: tokenDescription,
      image: tokenImage,
    };

    // Base64 encode the JSON
    const tokenURI = `data:application/json;base64,${btoa(JSON.stringify(tokenMetadata))}`;

    writeContract({
      address: deployedContract,
      abi: ap1155Abi,
      functionName: "configureToken",
      args: [
        BigInt(tokenId),
        tokenURI,
        expiration
          ? BigInt(Math.floor(new Date(expiration).getTime() / 1000))
          : 0n,
      ],
    });
  };

  return (
    <div className="min-h-screen py-16 px-6 sm:px-8 lg:px-12">
      <div className="max-w-4xl mx-auto bg-gray-800 rounded-lg shadow-lg p-8">
        <h1 className="text-3xl font-bold text-white mb-2">
          Create Your Art Collection
        </h1>
        <p className="text-gray-300 mb-6">
          Set up your collection and create your first artwork
        </p>

        {/* Progress Indicator */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <div
              className={`flex items-center ${currentStep >= 1 ? "text-indigo-400" : "text-gray-500"}`}
            >
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                  currentStep >= 1
                    ? "bg-indigo-600 text-white"
                    : "bg-gray-700 text-gray-400"
                }`}
              >
                1
              </div>
              <span className="ml-2 text-sm font-medium">Collection</span>
            </div>
            <div
              className={`flex-1 h-px mx-4 ${currentStep >= 2 ? "bg-indigo-600" : "bg-gray-700"}`}
            ></div>
            <div
              className={`flex items-center ${currentStep >= 2 ? "text-indigo-400" : "text-gray-500"}`}
            >
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                  currentStep >= 2
                    ? "bg-indigo-600 text-white"
                    : "bg-gray-700 text-gray-400"
                }`}
              >
                2
              </div>
              <span className="ml-2 text-sm font-medium">Artwork</span>
            </div>
          </div>
        </div>

        {isConnected && (
          <div className="mb-6 p-4 bg-blue-900 border border-blue-600 text-blue-200 rounded">
            <p className="font-medium">Connected wallet:</p>
            <p className="font-mono text-sm">{address}</p>
            <p className="text-sm mt-2">
              Make sure this wallet is the creator of the contract, or the
              transaction will fail.
            </p>
          </div>
        )}

        {!isConnected && (
          <div className="mb-6 p-4 bg-yellow-900 border border-yellow-600 text-yellow-200 rounded">
            <p className="mb-3">
              Please connect your wallet to create artwork.
            </p>
            <ConnectKitButton />
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-10">
          {/* Step 1: Collection Information */}
          {currentStep === 1 && (
            <div>
              <h2 className="text-xl font-semibold text-white mb-4">
                Collection Information
              </h2>
              <p className="text-gray-300 mb-6">
                Define your collection's identity and visual style
              </p>

              <div className="grid grid-cols-1 gap-8">
                <div>
                  <label
                    htmlFor="collectionName"
                    className="block text-sm font-medium text-gray-200 mb-2"
                  >
                    Collection Name *
                  </label>
                  <input
                    type="text"
                    id="collectionName"
                    value={collectionName}
                    onChange={(e) => setCollectionName(e.target.value)}
                    className="mt-1 block w-full px-4 py-3 rounded-md border-gray-600 bg-gray-700 text-white shadow-sm focus:border-indigo-400 focus:ring-indigo-400"
                    placeholder="My Art Collection"
                    required
                  />
                </div>

                <div>
                  <label
                    htmlFor="collectionSymbol"
                    className="block text-sm font-medium text-gray-200"
                  >
                    Collection Symbol *
                  </label>
                  <input
                    type="text"
                    id="collectionSymbol"
                    value={collectionSymbol}
                    onChange={(e) => setCollectionSymbol(e.target.value)}
                    className="mt-1 block w-full px-4 py-3 rounded-md border-gray-600 bg-gray-700 text-white shadow-sm focus:border-indigo-400 focus:ring-indigo-400"
                    placeholder="ART"
                    required
                  />
                </div>

                <div className="md:col-span-2">
                  <label
                    htmlFor="collectionDescription"
                    className="block text-sm font-medium text-gray-200"
                  >
                    Collection Description *
                  </label>
                  <textarea
                    id="collectionDescription"
                    value={collectionDescription}
                    onChange={(e) => setCollectionDescription(e.target.value)}
                    rows={4}
                    className="mt-1 block w-full px-4 py-3 rounded-md border-gray-600 bg-gray-700 text-white shadow-sm focus:border-indigo-400 focus:ring-indigo-400"
                    placeholder="Describe your art collection..."
                    required
                  />
                </div>

                <div>
                  <label
                    htmlFor="collectionImage"
                    className="block text-sm font-medium text-gray-200"
                  >
                    Collection Image URL *
                  </label>
                  <input
                    type="url"
                    id="collectionImage"
                    value={collectionImage}
                    onChange={(e) => setCollectionImage(e.target.value)}
                    className="mt-1 block w-full px-4 py-3 rounded-md border-gray-600 bg-gray-700 text-white shadow-sm focus:border-indigo-400 focus:ring-indigo-400"
                    placeholder="https://your-collection-image.com"
                    required
                  />
                  <p className="mt-1 text-sm text-gray-400">
                    Banner image for your collection
                  </p>

                  {collectionImage && (
                    <div className="mt-4">
                      <p className="text-sm text-gray-300 mb-2">Preview:</p>
                      <div className="relative w-full max-w-md mx-auto">
                        <img
                          src={collectionImage}
                          alt="Collection preview"
                          className="w-full h-auto rounded-lg border border-gray-600 object-cover max-h-48"
                          onError={(e) => {
                            e.currentTarget.style.display = "none";
                          }}
                          onLoad={(e) => {
                            e.currentTarget.style.display = "block";
                          }}
                        />
                      </div>
                    </div>
                  )}

                  <div>
                    <label
                      htmlFor="collectionExternalLink"
                      className="block text-sm font-medium text-gray-200 mt-8"
                    >
                      Collection Website (optional)
                    </label>
                    <input
                      type="url"
                      id="collectionExternalLink"
                      value={collectionExternalLink}
                      onChange={(e) =>
                        setCollectionExternalLink(e.target.value)
                      }
                      className="mt-1 block w-full px-4 py-3 rounded-md border-gray-600 bg-gray-700 text-white shadow-sm focus:border-indigo-400 focus:ring-indigo-400"
                      placeholder="https://your-artist-website.com"
                    />
                    <p className="mt-1 text-sm text-gray-400">
                      Link to your artist website
                    </p>
                  </div>
                </div>
              </div>

              <div className="mt-8 flex justify-end">
                <button
                  type="button"
                  onClick={nextStep}
                  disabled={factoryPending || factoryConfirming}
                  className="px-6 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {factoryPending
                    ? "Deploying Collection..."
                    : factoryConfirming
                      ? "Confirming Deployment..."
                      : "Next: Create Artwork →"}
                </button>
              </div>
            </div>
          )}

          {/* Step 2: Artwork Information */}
          {currentStep === 2 && (
            <div>
              <h2 className="text-xl font-semibold text-white mb-4">
                Artwork Information
              </h2>
              <p className="text-gray-300 mb-4">
                Create your first artwork in this collection
              </p>

              <div className="grid grid-cols-1 gap-8">
                <div>
                  <label
                    htmlFor="tokenId"
                    className="block text-sm font-medium text-gray-200 mb-2"
                  >
                    Artwork ID *
                  </label>
                  <input
                    type="number"
                    id="tokenId"
                    value={tokenId}
                    onChange={(e) => setTokenId(e.target.value)}
                    className="mt-1 block w-full px-4 py-3 rounded-md border-gray-600 bg-gray-700 text-white shadow-sm focus:border-indigo-400 focus:ring-indigo-400"
                    placeholder="Choose a unique ID for your artwork"
                    min="1"
                    required
                  />
                </div>

                <div>
                  <label
                    htmlFor="tokenName"
                    className="block text-sm font-medium text-gray-200"
                  >
                    Artwork Title *
                  </label>
                  <input
                    type="text"
                    id="tokenName"
                    value={tokenName}
                    onChange={(e) => setTokenName(e.target.value)}
                    className="mt-1 block w-full px-4 py-3 rounded-md border-gray-600 bg-gray-700 text-white shadow-sm focus:border-indigo-400 focus:ring-indigo-400"
                    placeholder="Give your artwork a title"
                    required
                  />
                </div>

                <div>
                  <label
                    htmlFor="tokenImage"
                    className="block text-sm font-medium text-gray-200"
                  >
                    Artwork Image URL *
                  </label>
                  <input
                    type="url"
                    id="tokenImage"
                    value={tokenImage}
                    onChange={(e) => setTokenImage(e.target.value)}
                    className="mt-1 block w-full px-4 py-3 rounded-md border-gray-600 bg-gray-700 text-white shadow-sm focus:border-indigo-400 focus:ring-indigo-400"
                    placeholder="https://your-artwork-image.com"
                    required
                  />
                  <p className="mt-1 text-sm text-gray-400">
                    Direct link to your artwork image
                  </p>

                  {tokenImage && (
                    <div className="mt-4">
                      <p className="text-sm text-gray-300 mb-2">Preview:</p>
                      <div className="relative w-full max-w-sm mx-auto">
                        <img
                          src={tokenImage}
                          alt="Artwork preview"
                          className="w-full h-auto rounded-lg border border-gray-600 object-contain max-h-64"
                          onError={(e) => {
                            e.currentTarget.style.display = "none";
                          }}
                          onLoad={(e) => {
                            e.currentTarget.style.display = "block";
                          }}
                        />
                      </div>
                    </div>
                  )}
                </div>

                <div>
                  <label
                    htmlFor="tokenDescription"
                    className="block text-sm font-medium text-gray-200 mb-2"
                  >
                    Artwork Description *
                  </label>
                  <textarea
                    id="tokenDescription"
                    value={tokenDescription}
                    onChange={(e) => setTokenDescription(e.target.value)}
                    rows={5}
                    className="mt-1 block w-full px-4 py-3 rounded-md border-gray-600 bg-gray-700 text-white shadow-sm focus:border-indigo-400 focus:ring-indigo-400"
                    placeholder="Tell the story behind your artwork..."
                    required
                  />
                </div>

                <div>
                  <label
                    htmlFor="expiration"
                    className="block text-sm font-medium text-gray-200"
                  >
                    Minting Deadline (optional)
                  </label>
                  <input
                    type="datetime-local"
                    id="expiration"
                    value={expiration}
                    onChange={(e) => setExpiration(e.target.value)}
                    className="mt-1 block w-full px-4 py-3 rounded-md border-gray-600 bg-gray-700 text-white shadow-sm focus:border-indigo-400 focus:ring-indigo-400"
                  />
                  <p className="mt-1 text-sm text-gray-400">
                    When should minting close?
                  </p>
                </div>
              </div>

              <div className="mt-8 flex justify-between">
                <button
                  type="button"
                  onClick={prevStep}
                  className="px-6 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"
                >
                  ← Back to Collection
                </button>
                <button
                  type="submit"
                  disabled={isPending || isConfirming || !isConnected}
                  className="px-6 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isPending
                    ? "Creating Your Artwork..."
                    : isConfirming
                      ? "Confirming..."
                      : "Create Artwork"}
                </button>
              </div>
            </div>
          )}
        </form>

        {isSuccess && (
          <div className="mt-6 p-4 bg-green-900 border border-green-600 text-green-200 rounded">
            <div className="font-medium mb-2">
              🎨 Your artwork has been created!
            </div>
             <div className="text-sm space-y-1">
               <div>
                 Collection:{" "}
                 <span className="font-mono">"{collectionName}"</span>
               </div>
               <div>
                 Collection Address: <span className="font-mono">{deployedContract}</span>
               </div>
               <div>
                 Artwork ID: <span className="font-mono">{tokenId}</span>
               </div>
               <div>
                 Title: <span className="font-mono">"{tokenName}"</span>
               </div>
              <div className="mt-3">
                <a
                  href={`https://basescan.org/tx/${hash}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-green-300 hover:text-green-200 underline"
                >
                  View transaction on BaseScan ↗
                </a>
              </div>
            </div>
          </div>
        )}

        {factoryError && (
          <div className="mt-6 p-4 bg-red-900 border border-red-600 text-red-200 rounded">
            Deployment Error: {factoryError.message.split(".")[0]}
          </div>
        )}

        {error && (
          <div className="mt-6 p-4 bg-red-900 border border-red-600 text-red-200 rounded">
            Error: {error.message.split(".")[0]}
          </div>
        )}

        <div className="mt-8 text-center">
          <Link
            to="/"
            className="text-indigo-400 hover:text-indigo-300 text-sm"
          >
            ← Back to Home
          </Link>
        </div>
      </div>

      {toast && toast.visible && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  );
}
