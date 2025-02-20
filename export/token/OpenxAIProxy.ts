export const OpenxAIProxyContract = {
  address: "0x32fee802CA56DC9544CF239DD8092C1AeC88953d",
  abi: [
    {
      type: "constructor",
      inputs: [
        { name: "implementation", type: "address", internalType: "address" },
        { name: "_data", type: "bytes", internalType: "bytes" },
      ],
      stateMutability: "payable",
    },
    { type: "fallback", stateMutability: "payable" },
    {
      type: "event",
      name: "Upgraded",
      inputs: [
        {
          name: "implementation",
          type: "address",
          indexed: true,
          internalType: "address",
        },
      ],
      anonymous: false,
    },
    {
      type: "error",
      name: "AddressEmptyCode",
      inputs: [{ name: "target", type: "address", internalType: "address" }],
    },
    {
      type: "error",
      name: "ERC1967InvalidImplementation",
      inputs: [
        { name: "implementation", type: "address", internalType: "address" },
      ],
    },
    { type: "error", name: "ERC1967NonPayable", inputs: [] },
    { type: "error", name: "FailedCall", inputs: [] },
  ],
} as const;
