import { Loader } from '@mantine/core';

export const LoadingIndicator = () => {
  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      padding: '1rem'
    }}>
      <Loader size="sm" />
    </div>
  );
};

