export const getEnvs = () => {
  if (!process.env.GAS_PRICE) {
    throw Error("Missing process.env.GAS_PRICE");
  }

  if (!process.env.ESCROW_IMPL) {
    throw Error("Missing process.env.ESCROW_IMPL");
  }

  return {
    escrowImpl: process.env.ESCROW_IMPL,
  };
};
