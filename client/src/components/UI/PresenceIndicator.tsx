import React, { memo } from 'react';
import { Box } from '@mantine/core';
import './PresenceIndicator.css';

interface PresenceIndicatorProps {
  isOnline: boolean;
  size?: 'sm' | 'md';
  className?: string;
  style?: React.CSSProperties;
}

export const PresenceIndicator: React.FC<PresenceIndicatorProps> = memo(({ 
  isOnline, 
  size = 'sm',
  className,
  style 
}) => {
  const sizePx = size === 'sm' ? 8 : 12;
  const borderSize = size === 'sm' ? 2 : 3;

  const indicatorStyle: React.CSSProperties = {
    width: sizePx,
    height: sizePx,
    borderRadius: '50%',
    position: 'absolute',
    top: -2,
    right: -2,
    border: isOnline ? 'none' : `${borderSize}px solid #e9ecef`,
    backgroundColor: isOnline ? '#51cf66' : 'transparent',
    zIndex: 10,
    ...(isOnline && {
      animation: 'pulse 2s infinite',
    }),
    ...style,
  };

  return (
    <>
      <Box
        className={className}
        style={indicatorStyle}
        aria-label={isOnline ? 'Online' : 'Offline'}
      />
    </>
  );
});
